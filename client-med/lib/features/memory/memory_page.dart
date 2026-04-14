import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_paths.dart';
import '../../providers/providers.dart';

class MemoryPage extends ConsumerStatefulWidget {
  const MemoryPage({super.key});

  @override
  ConsumerState<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends ConsumerState<MemoryPage> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _memories = const [];

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
            ApiPaths.memory,
            queryParameters: {'profile_id': profileId},
          );
      final raw = resp.data?['memories'];
      final items = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) items.add(Map<String, dynamic>.from(e));
        }
      }
      setState(() => _memories = items);
    } catch (e) {
      setState(() => _error = 'Tải memory thất bại: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final keyCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm memory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(labelText: 'Key'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (keyCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(apiServiceProvider).client.post(
            ApiPaths.memory,
            queryParameters: {'profile_id': profileId},
            data: {
              'key': keyCtrl.text.trim(),
              'value': valueCtrl.text.trim(),
              'source': 'user',
              'confidence': 1.0,
            },
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu memory thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Thêm memory',
          ),
        ],
      ),
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
            if (!_loading && _memories.isEmpty) const Text('Chưa có memory.'),
            for (final m in _memories)
              Card(
                child: ListTile(
                  title: Text((m['key'] ?? '').toString()),
                  subtitle: Text((m['value'] ?? '').toString()),
                  trailing: Text((m['source'] ?? 'user').toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
