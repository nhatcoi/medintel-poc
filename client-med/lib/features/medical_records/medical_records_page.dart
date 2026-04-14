import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_paths.dart';
import '../../providers/providers.dart';

class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _records = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) {
      setState(() => _error = 'Không tìm thấy profile đang chọn.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ref.read(apiServiceProvider).client.get<Map<String, dynamic>>(
            ApiPaths.medicalRecords,
            queryParameters: {'profile_id': profileId},
          );
      final raw = resp.data?['records'];
      final items = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) items.add(Map<String, dynamic>.from(e));
        }
      }
      setState(() => _records = items);
    } catch (e) {
      setState(() => _error = 'Tải hồ sơ bệnh án thất bại: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ bệnh án')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!_loading && _records.isEmpty)
              const Text('Chưa có dữ liệu bệnh án.'),
            for (final r in _records)
              Card(
                child: ListTile(
                  title: Text((r['disease_name'] ?? 'Không rõ bệnh').toString()),
                  subtitle: Text(
                    'Bắt đầu: ${(r['treatment_start_date'] ?? '-')}'
                    '\nTrạng thái: ${(r['treatment_status'] ?? '-')}'
                    '\nLoại điều trị: ${(r['treatment_type'] ?? '-')}',
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
