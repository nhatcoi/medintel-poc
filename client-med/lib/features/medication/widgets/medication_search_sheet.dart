import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/api_paths.dart';
import '../../../providers/providers.dart';

class MedicationSearchCandidate {
  const MedicationSearchCandidate({
    required this.name,
    required this.summary,
    this.dosageSuggestion,
    this.instructionsSuggestion,
    this.scheduleSuggestion,
  });

  final String name;
  final String summary;
  final String? dosageSuggestion;
  final String? instructionsSuggestion;
  final String? scheduleSuggestion;
}

class MedicationSearchSheet extends ConsumerStatefulWidget {
  const MedicationSearchSheet({super.key});

  @override
  ConsumerState<MedicationSearchSheet> createState() => _MedicationSearchSheetState();
}

class _MedicationSearchSheetState extends ConsumerState<MedicationSearchSheet> {
  final _queryCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<MedicationSearchCandidate> _items = const [];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _items = const [];
    });
    try {
      final searchResp = await ref.read(apiServiceProvider).client.get<Map<String, dynamic>>(
            ApiPaths.treatmentMedicationsSearch,
            queryParameters: {'q': q, 'limit': 12},
          );
      final raw = searchResp.data?['items'];
      final out = <MedicationSearchCandidate>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final name = (m['medication_name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          final ingredient = (m['active_ingredient'] ?? '').toString().trim();
          final indications = (m['indications'] ?? '').toString().trim();
          final summary = [
            if (ingredient.isNotEmpty) ingredient,
            if (indications.isNotEmpty) indications,
          ].join(' • ');
          out.add(
            MedicationSearchCandidate(
              name: name,
              summary: summary.isEmpty ? 'Chưa có mô tả' : summary,
              scheduleSuggestion: '08:00',
            ),
          );
        }
      }

      if (out.isNotEmpty) {
        setState(() => _items = out);
      } else {
        // fallback: ask agentic to synthesize one suggestion when DB returns empty.
        final profileId = ref.read(authProvider).user?.id;
        final prompt = '''
Tìm thuốc "$q". Trả về JSON duy nhất:
{"name":"", "summary":"", "dosage":"", "instructions":"", "schedule_time":"08:00"}
''';
        final resp = await ref.read(apiServiceProvider).client.post<Map<String, dynamic>>(
              ApiPaths.chatMessage,
              data: {
                'text': prompt,
                if (profileId != null && profileId.isNotEmpty) 'profile_id': profileId,
              },
            );
        final reply = (resp.data?['reply'] ?? '').toString();
        final jsonObj = _tryParseFirstJson(reply);
        if (jsonObj == null) {
          setState(() {
            _items = [
              MedicationSearchCandidate(
                name: q,
                summary: reply.isEmpty ? 'Không có phản hồi từ search' : reply,
                scheduleSuggestion: '08:00',
              ),
            ];
          });
        } else {
          setState(() {
            _items = [
              MedicationSearchCandidate(
                name: (jsonObj['name'] ?? q).toString(),
                summary: (jsonObj['summary'] ?? '').toString(),
                dosageSuggestion: jsonObj['dosage']?.toString(),
                instructionsSuggestion: jsonObj['instructions']?.toString(),
                scheduleSuggestion: (jsonObj['schedule_time'] ?? '08:00').toString(),
              ),
            ];
          });
        }
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('receive timeout')) {
        setState(() => _error = 'Tìm kiếm đang quá tải, thử lại sau vài giây.');
      } else {
        setState(() => _error = 'Không tìm được dữ liệu thuốc lúc này.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(999))),
              ),
              const SizedBox(height: 12),
              const Text('Tìm thuốc', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'Full-text search',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _queryCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên thuốc',
                  hintText: 'Ví dụ: Panadol',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: IconButton(
                    onPressed: _loading ? null : _search,
                    icon: const Icon(LucideIcons.arrowRight),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 10),
              if (_loading) const LinearProgressIndicator(),
              for (final item in _items)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic>? _tryParseFirstJson(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  final raw = text.substring(start, end + 1);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return null;
}

String? _extractDosage(String text) {
  final reg = RegExp(r'(\d+\s?(mg|g|ml|viên|vien))', caseSensitive: false);
  return reg.firstMatch(text)?.group(0);
}

String? _extractInstruction(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('sau ăn') || lower.contains('sau an')) return 'Sau ăn';
  if (lower.contains('trước ăn') || lower.contains('truoc an')) return 'Trước ăn';
  return null;
}
