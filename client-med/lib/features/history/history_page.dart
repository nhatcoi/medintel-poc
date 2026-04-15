import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/ui_tokens.dart';
import '../../providers/providers.dart';
import '../treatment/data/treatment_models.dart';
import '../treatment/data/treatment_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  DateTime _selectedDate = _dateOnly(DateTime.now());
  String _selectedStatus = 'all';
  int _rangeDays = 7;
  bool _sortNewestFirst = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _reload() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadMedications(profileId);
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = _dateOnly(picked));
  }

  List<MedicationLogItem> _filterLogs(List<MedicationLogItem> logs) {
    final start = _dateOnly(
      _selectedDate.subtract(Duration(days: _rangeDays - 1)),
    );
    final end = _dateOnly(_selectedDate);
    final q = _searchQuery.trim().toLowerCase();
    final out =
        logs.where((log) {
          final day = _dateOnly(log.scheduledDatetime.toLocal());
          final statusOk =
              _selectedStatus == 'all' || log.status == _selectedStatus;
          final inRange = !day.isBefore(start) && !day.isAfter(end);
          final queryOk =
              q.isEmpty || log.medicationName.toLowerCase().contains(q);
          return inRange && statusOk && queryOk;
        }).toList()..sort(
          (a, b) => _sortNewestFirst
              ? b.scheduledDatetime.compareTo(a.scheduledDatetime)
              : a.scheduledDatetime.compareTo(b.scheduledDatetime),
        );
    return out;
  }

  List<MedicationLogItem> _logsForCharts(List<MedicationLogItem> logs) {
    final start = _dateOnly(
      _selectedDate.subtract(Duration(days: _rangeDays - 1)),
    );
    final end = _dateOnly(_selectedDate);
    final q = _searchQuery.trim().toLowerCase();
    final out =
        logs.where((log) {
            final day = _dateOnly(log.scheduledDatetime.toLocal());
            final inRange = !day.isBefore(start) && !day.isAfter(end);
            final queryOk =
                q.isEmpty || log.medicationName.toLowerCase().contains(q);
            return inRange && queryOk;
          }).toList()
          ..sort((a, b) => a.scheduledDatetime.compareTo(b.scheduledDatetime));
    return out;
  }

  List<_DailyAdherencePoint> _buildDailyAdherence(
    List<MedicationLogItem> logs,
  ) {
    final start = _dateOnly(
      _selectedDate.subtract(Duration(days: _rangeDays - 1)),
    );
    final byDay = <DateTime, List<MedicationLogItem>>{};
    for (final log in logs) {
      final day = _dateOnly(log.scheduledDatetime.toLocal());
      byDay.putIfAbsent(day, () => <MedicationLogItem>[]).add(log);
    }
    return List.generate(_rangeDays, (index) {
      final day = _dateOnly(start.add(Duration(days: index)));
      final dayLogs = byDay[day] ?? const <MedicationLogItem>[];
      final total = dayLogs.length;
      var adhered = 0;
      for (final log in dayLogs) {
        if (log.status == 'taken' || log.status == 'late') adhered += 1;
      }
      final rate = total == 0 ? 0.0 : adhered / total;
      return _DailyAdherencePoint(
        day: day,
        total: total,
        adhered: adhered,
        rate: rate,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(treatmentProvider);
    final filtered = _filterLogs(state.logs);
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final summary = _rangeDays == 30 ? state.summary30 : state.summary;
    final totalVisible = filtered.length;
    final chartLogs = _logsForCharts(state.logs);
    final dailyPoints = _buildDailyAdherence(chartLogs);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adherenceTitle),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Chọn ngày',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            UiTokens.pagePadding,
            UiTokens.sectionGap,
            UiTokens.pagePadding,
            24,
          ),
          children: [
            _SummaryCard(
              summary: summary,
              rangeDays: _rangeDays,
              dailyPoints: dailyPoints,
            ),
            const SizedBox(height: UiTokens.sectionGap),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đến ngày: $dateLabel',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Đổi ngày'),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: UiTokens.chipGap,
              runSpacing: UiTokens.chipGap,
              children: [
                _StatusChip(
                  label: '7 ngày',
                  selected: _rangeDays == 7,
                  onTap: () => setState(() => _rangeDays = 7),
                ),
                _StatusChip(
                  label: '30 ngày',
                  selected: _rangeDays == 30,
                  onTap: () => setState(() => _rangeDays = 30),
                ),
              ],
            ),
            const SizedBox(height: UiTokens.chipGap),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm theo tên thuốc',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: UiTokens.chipGap),
            Text(
              'Đang hiển thị: $totalVisible log',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: UiTokens.chipGap),
            Wrap(
              spacing: UiTokens.chipGap,
              runSpacing: UiTokens.chipGap,
              children: [
                _StatusChip(
                  label: 'Mới nhất',
                  selected: _sortNewestFirst,
                  onTap: () => setState(() => _sortNewestFirst = true),
                ),
                _StatusChip(
                  label: 'Cũ nhất',
                  selected: !_sortNewestFirst,
                  onTap: () => setState(() => _sortNewestFirst = false),
                ),
              ],
            ),
            const SizedBox(height: UiTokens.chipGap),
            Wrap(
              spacing: UiTokens.chipGap,
              runSpacing: UiTokens.chipGap,
              children: [
                _StatusChip(
                  label: 'Tất cả',
                  selected: _selectedStatus == 'all',
                  onTap: () => setState(() => _selectedStatus = 'all'),
                ),
                _StatusChip(
                  label: 'Đã uống',
                  selected: _selectedStatus == 'taken',
                  onTap: () => setState(() => _selectedStatus = 'taken'),
                ),
                _StatusChip(
                  label: 'Muộn',
                  selected: _selectedStatus == 'late',
                  onTap: () => setState(() => _selectedStatus = 'late'),
                ),
                _StatusChip(
                  label: 'Bỏ lỡ',
                  selected: _selectedStatus == 'missed',
                  onTap: () => setState(() => _selectedStatus = 'missed'),
                ),
                _StatusChip(
                  label: 'Bỏ qua',
                  selected: _selectedStatus == 'skipped',
                  onTap: () => setState(() => _selectedStatus = 'skipped'),
                ),
              ],
            ),
            const SizedBox(height: UiTokens.sectionGap),
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!state.loading && filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.adherenceNoData),
              ),
            for (final log in filtered)
              Card(
                margin: const EdgeInsets.only(top: UiTokens.chipGap),
                child: ListTile(
                  onTap: () => _showLogDetail(log),
                  title: _HighlightedText(
                    text: log.medicationName,
                    query: _searchQuery,
                  ),
                  subtitle: Text(
                    'Giờ dự kiến: ${DateFormat('HH:mm').format(log.scheduledDatetime.toLocal())}',
                  ),
                  trailing: _StatusBadge(
                    status: log.status,
                    label: _labelForStatus(log.status),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _rangeDays = 7;
      _sortNewestFirst = true;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'taken':
        return 'Đã uống';
      case 'late':
        return 'Muộn';
      case 'missed':
        return 'Bỏ lỡ';
      case 'skipped':
        return 'Bỏ qua';
      default:
        return status;
    }
  }

  void _showLogDetail(MedicationLogItem log) {
    final scheduled = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(log.scheduledDatetime.toLocal());
    final actual = log.actualDatetime == null
        ? 'Chưa ghi nhận'
        : DateFormat('dd/MM/yyyy HH:mm').format(log.actualDatetime!.toLocal());
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var updating = false;
        Future<void> updateStatus(String status) async {
          if (updating) return;
          final profileId = ref.read(activeProfileIdProvider);
          if (profileId == null || profileId.isEmpty) return;
          updating = true;
          try {
            await ref
                .read(treatmentProvider.notifier)
                .updateLogStatus(
                  profileId: profileId,
                  medicationId: log.medicationId,
                  logId: log.logId,
                  status: status,
                );
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã cập nhật trạng thái: ${_labelForStatus(status)}',
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
            }
          } finally {
            updating = false;
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.medicationName,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _StatusBadge(
                status: log.status,
                label: _labelForStatus(log.status),
              ),
              const SizedBox(height: 12),
              Text('Giờ dự kiến: $scheduled'),
              const SizedBox(height: 4),
              Text('Giờ thực tế: $actual'),
              if (log.notes != null && log.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Ghi chú: ${log.notes!}'),
              ],
              const SizedBox(height: 14),
              Text(
                'Đổi trạng thái nhanh',
                style: Theme.of(
                  ctx,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => updateStatus('taken'),
                    child: const Text('Đã uống'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => updateStatus('late'),
                    child: const Text('Muộn'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => updateStatus('missed'),
                    child: const Text('Bỏ lỡ'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => updateStatus('skipped'),
                    child: const Text('Bỏ qua'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.rangeDays,
    required this.dailyPoints,
  });

  final AdherenceSummary? summary;
  final int rangeDays;
  final List<_DailyAdherencePoint> dailyPoints;

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const SizedBox.shrink();
    final rate = (summary!.complianceRate * 100).toStringAsFixed(1);
    final chartSections = <PieChartSectionData>[
      PieChartSectionData(
        value: summary!.taken.toDouble(),
        color: const Color(0xFF2E7DFF),
        radius: 40,
        title: '',
      ),
      PieChartSectionData(
        value: summary!.late.toDouble(),
        color: const Color(0xFFFFB74D),
        radius: 40,
        title: '',
      ),
      PieChartSectionData(
        value: summary!.missed.toDouble(),
        color: const Color(0xFFEF5350),
        radius: 40,
        title: '',
      ),
      PieChartSectionData(
        value: summary!.skipped.toDouble(),
        color: const Color(0xFF90A4AE),
        radius: 40,
        title: '',
      ),
    ];

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < dailyPoints.length; i += 1) {
      final p = dailyPoints[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: p.rate * 100,
              width: 12,
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [Color(0xFF7CC6FF), Color(0xFF2E7DFF)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan $rangeDays ngày',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('Tổng: ${summary!.total}'),
                Text('Đã uống: ${summary!.taken}'),
                Text('Bỏ lỡ: ${summary!.missed}'),
                Text('Tỉ lệ tuân thủ: $rate%'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: PieChart(
                    PieChartData(
                      sections: chartSections,
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LegendRow(label: 'Đã uống', color: Color(0xFF2E7DFF)),
                      SizedBox(height: 6),
                      _LegendRow(label: 'Muộn', color: Color(0xFFFFB74D)),
                      SizedBox(height: 6),
                      _LegendRow(label: 'Bỏ lỡ', color: Color(0xFFEF5350)),
                      SizedBox(height: 6),
                      _LegendRow(label: 'Bỏ qua', color: Color(0xFF90A4AE)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Xu hướng tuân thủ theo ngày (%)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  barGroups: bars,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 34,
                        interval: 25,
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dailyPoints.length) {
                            return const SizedBox.shrink();
                          }
                          final day = dailyPoints[idx].day;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('dd/MM').format(day),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final point = dailyPoints[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('dd/MM').format(point.day)}\n${(point.rate * 100).toStringAsFixed(0)}% (${point.adhered}/${point.total})',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DailyAdherencePoint {
  const _DailyAdherencePoint({
    required this.day,
    required this.total,
    required this.adhered,
    required this.rate,
  });

  final DateTime day;
  final int total;
  final int adhered;
  final double rate;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.chipRadius),
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      'taken' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      'late' => (Colors.amber.shade100, Colors.amber.shade900),
      'missed' => (scheme.errorContainer, scheme.onErrorContainer),
      'skipped' => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) {
      return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
    }

    final lower = text.toLowerCase();
    final qLower = q.toLowerCase();
    final idx = lower.indexOf(qLower);
    if (idx < 0) {
      return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
    }

    final before = text.substring(0, idx);
    final match = text.substring(idx, idx + q.length);
    final after = text.substring(idx + q.length);
    final scheme = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(
          context,
        ).style.copyWith(fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              backgroundColor: scheme.secondaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
