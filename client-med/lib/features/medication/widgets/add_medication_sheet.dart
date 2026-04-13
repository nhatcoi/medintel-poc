import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    'meth',
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

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text.trim();
    final blocked = _isBlockedMedication(name);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(999)))),
              const SizedBox(height: 12),
              const Text('Thêm thuốc', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _doseCtrl, decoration: const InputDecoration(labelText: 'Liều'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _unitCtrl, decoration: const InputDecoration(labelText: 'Đơn vị'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Giờ uống (HH:mm)')),
              const SizedBox(height: 10),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Trước ăn')),
                  ButtonSegment(value: 1, label: Text('Sau ăn')),
                  ButtonSegment(value: 2, label: Text('Trong ăn')),
                ],
                selected: {_mealMode},
                onSelectionChanged: (v) => setState(() => _mealMode = v.first),
              ),
              const SizedBox(height: 10),
              TextField(controller: _noteCtrl, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(LucideIcons.fileText))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: blocked ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  child: Text(blocked ? 'Không thể lưu' : 'Lưu thuốc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isBlockedMedication(String name) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty) return false;
    for (final k in _blockedKeywords) {
      if (n.contains(k)) return true;
    }
    return false;
  }
}
