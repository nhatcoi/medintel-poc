import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../treatment/data/treatment_provider.dart';

class AdherencePlaceholder extends ConsumerStatefulWidget {
  const AdherencePlaceholder({super.key});

  @override
  ConsumerState<AdherencePlaceholder> createState() => _AdherencePlaceholderState();
}

class _AdherencePlaceholderState extends ConsumerState<AdherencePlaceholder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final profileId = ref.read(authProvider).user?.id;
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentProvider);
    final summary = state.summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Tuân thủ điều trị')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (summary == null) ...[
              if (state.loading) const LinearProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Chưa có dữ liệu tuân thủ.'),
            ] else ...[
              _tile(context, 'Tổng liều (${summary.days} ngày)', summary.total.toString()),
              _tile(context, 'Đã uống', summary.taken.toString()),
              _tile(context, 'Bỏ lỡ', summary.missed.toString()),
              _tile(context, 'Bỏ qua', summary.skipped.toString()),
              _tile(context, 'Uống trễ', summary.late.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
