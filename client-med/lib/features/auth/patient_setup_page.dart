import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../providers/providers.dart';

class PatientSetupPage extends ConsumerStatefulWidget {
  const PatientSetupPage({super.key});

  @override
  ConsumerState<PatientSetupPage> createState() => _PatientSetupPageState();
}

class _PatientSetupPageState extends ConsumerState<PatientSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _gender;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).completeSetup(
        fullName: _nameCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
        gender: _gender,
        medicalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('Connection refused')
              ? 'Không thể kết nối server. Vui lòng kiểm tra kết nối.'
              : 'Không thể lưu thông tin. Vui lòng thử lại.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      _dobCtrl.text = '${picked.day.toString().padLeft(2, '0')}'
          '/${picked.month.toString().padLeft(2, '0')}'
          '/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: VitalisColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: VitalisColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Thông tin cá nhân',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: VitalisColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Giúp MedIntel cá nhân hóa trải nghiệm cho bạn',
                    style: text.bodyMedium?.copyWith(color: VitalisColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),

                  // Full name *
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecor('Họ và tên *', Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 14),

                  // Date of birth
                  TextFormField(
                    controller: _dobCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: _inputDecor('Ngày sinh', Icons.calendar_today_outlined),
                  ),
                  const SizedBox(height: 14),

                  // Gender
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: _inputDecor('Giới tính', Icons.wc_outlined),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Nam')),
                      DropdownMenuItem(value: 'female', child: Text('Nữ')),
                      DropdownMenuItem(value: 'other', child: Text('Khác')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 14),

                  // Medical notes
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: _inputDecor('Ghi chú y tế (dị ứng, bệnh nền...)', Icons.medical_information_outlined),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: VitalisColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Hoàn tất'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: VitalisColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: VitalisColors.outlineVariantBase.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: VitalisColors.outlineVariantBase.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: VitalisColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
