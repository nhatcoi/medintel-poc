import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/ui_tokens.dart';
import 'medication_search_sheet.dart';

class AddMedicationFormData {
  const AddMedicationFormData({
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
    this.scheduleTimes = const [],
    this.notes,
  });

  final String name;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final List<String> scheduleTimes;
  final String? notes;
}

class AddMedicationSheet extends StatefulWidget {
  const AddMedicationSheet({
    super.key,
    this.initialCandidate,
  });

  final MedicationSearchCandidate? initialCandidate;

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  static const List<String> _blockedKeywords = [
    'ma túy',
    'ma tuy',
    'thuốc phiện',
    'thuoc phien',
    'opioid',
    'heroin',
    'cocaine',
    'ketamine',
    'methamphetamine',
    'cần sa',
    'can sa',
    'thuốc chuột',
    'thuoc chuot',
    'rat poison',
  ];

  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController(text: 'viên');
  final _timeCtrl = TextEditingController(text: '08:00');
  final _noteCtrl = TextEditingController();
  int _mealMode = 1;
  static const List<String> _unitQuickPicks = ['viên', 'ml', 'gói', 'ống', 'giọt'];
  static const List<String> _timeQuickPicks = ['08:00', '12:00', '18:00', '21:00'];

  @override
  void initState() {
    super.initState();
    final c = widget.initialCandidate;
    if (c != null) {
      _nameCtrl.text = c.name;
      if (c.dosageSuggestion != null && c.dosageSuggestion!.trim().isNotEmpty) {
        final parts = c.dosageSuggestion!.trim().split(RegExp(r'\s+'));
        _doseCtrl.text = parts.first;
        if (parts.length > 1) _unitCtrl.text = parts.sublist(1).join(' ');
      }
      if (c.scheduleSuggestion != null && c.scheduleSuggestion!.trim().isNotEmpty) {
        _timeCtrl.text = c.scheduleSuggestion!;
      }
      if (c.instructionsSuggestion != null) {
        final lower = c.instructionsSuggestion!.toLowerCase();
        if (lower.contains('trước ăn') || lower.contains('truoc an')) {
          _mealMode = 0;
        } else if (lower.contains('trong ăn') || lower.contains('trong an')) {
          _mealMode = 2;
        } else {
          _mealMode = 1;
        }
      }
      _noteCtrl.text = c.summary;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _unitCtrl.dispose();
    _timeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (_isBlockedMedication(name)) return;
    if (!_isValidTime(_timeCtrl.text.trim())) {
      _showError('Giờ uống chưa hợp lệ. Vui lòng chọn theo định dạng HH:mm.');
      return;
    }
    final dose = _doseCtrl.text.trim().replaceAll(',', '.');
    final doseNum = double.tryParse(dose);
    if (doseNum == null || doseNum <= 0) {
      _showError('Liều dùng phải là số lớn hơn 0.');
      return;
    }
    final instruction = switch (_mealMode) {
      0 => 'Trước ăn',
      1 => 'Sau ăn',
      _ => 'Trong ăn',
    };
    Navigator.of(context).pop(
      AddMedicationFormData(
        name: name,
        dosage: '${_doseCtrl.text.trim()} ${_unitCtrl.text.trim()}'.trim(),
        frequency: '1 lần/ngày',
        instructions: instruction,
        scheduleTimes: [_timeCtrl.text.trim()],
        notes: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  bool _isValidTime(String input) {
    final t = input.trim();
    return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(t);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickTime() async {
    final current = _timeCtrl.text.trim();
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    if (_isValidTime(current)) {
      final parts = current.split(':');
      initial = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');
    setState(() => _timeCtrl.text = '$h:$m');
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text.trim();
    final blocked = _isBlockedMedication(name);
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  UiTokens.pagePadding,
                  UiTokens.sectionGap,
                  UiTokens.pagePadding,
                  UiTokens.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(999)))),
                    const SizedBox(height: UiTokens.sectionGap),
                    const Text('Thêm thuốc', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: UiTokens.sectionGap),
                    TextField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Tên thuốc'),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          blocked ? LucideIcons.shieldAlert : LucideIcons.shieldCheck,
                          size: 16,
                          color: blocked ? Theme.of(context).colorScheme.error : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            blocked
                                ? 'Thuốc này nằm trong danh mục không được phép sử dụng.'
                                : 'Thuốc hợp lệ để thêm vào kế hoạch điều trị.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: blocked
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UiTokens.sectionGap),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _doseCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Liều',
                              hintText: 'Ví dụ: 1',
                              helperText: 'Số lượng mỗi lần uống',
                            ),
                          ),
                        ),
                        const SizedBox(width: UiTokens.chipGap),
                        Expanded(
                          child: TextField(
                            controller: _unitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Đơn vị',
                              hintText: 'viên / ml / gói',
                              helperText: 'Có thể chọn nhanh bên dưới',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UiTokens.chipGap),
                    Wrap(
                      spacing: UiTokens.chipGap,
                      runSpacing: UiTokens.chipGap,
                      children: [
                        for (final unit in _unitQuickPicks)
                          ChoiceChip(
                            label: Text(unit),
                            selected: _unitCtrl.text.trim().toLowerCase() == unit,
                            onSelected: (_) => setState(() => _unitCtrl.text = unit),
                          ),
                      ],
                    ),
                    const SizedBox(height: UiTokens.sectionGap),
                    TextField(
                      controller: _timeCtrl,
                      readOnly: true,
                      onTap: _pickTime,
                      decoration: InputDecoration(
                        labelText: 'Giờ uống (HH:mm)',
                        helperText: 'Nhấn để chọn giờ chuẩn 24h',
                        suffixIcon: IconButton(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time_rounded),
                          tooltip: 'Chọn giờ',
                        ),
                      ),
                    ),
                    const SizedBox(height: UiTokens.chipGap),
                    Wrap(
                      spacing: UiTokens.chipGap,
                      runSpacing: UiTokens.chipGap,
                      children: [
                        for (final t in _timeQuickPicks)
                          ChoiceChip(
                            label: Text(t),
                            selected: _timeCtrl.text.trim() == t,
                            onSelected: (_) => setState(() => _timeCtrl.text = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: UiTokens.sectionGap),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Trước ăn')),
                        ButtonSegment(value: 1, label: Text('Sau ăn')),
                        ButtonSegment(value: 2, label: Text('Trong ăn')),
                      ],
                      selected: {_mealMode},
                      onSelectionChanged: (v) => setState(() => _mealMode = v.first),
                    ),
                    const SizedBox(height: UiTokens.sectionGap),
                    TextField(controller: _noteCtrl, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(LucideIcons.fileText))),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    UiTokens.pagePadding,
                    10,
                    UiTokens.pagePadding,
                    12 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: blocked ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(UiTokens.buttonHeight),
                      ),
                      child: Text(blocked ? 'Không thể lưu' : 'Lưu thuốc'),
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

  bool _isBlockedMedication(String name) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty) return false;
    final normalized = n
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = normalized.split(' ').toSet();
    for (final k in _blockedKeywords) {
      final key = k.toLowerCase().trim();
      if (key.contains(' ')) {
        if (normalized.contains(key)) return true;
      } else if (words.contains(key)) {
        return true;
      }
    }
    return false;
  }
}
