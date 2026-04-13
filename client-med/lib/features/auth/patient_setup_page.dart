import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../providers/providers.dart';

class PatientSetupPage extends ConsumerStatefulWidget {
  const PatientSetupPage({super.key});

  @override
  ConsumerState<PatientSetupPage> createState() => _PatientSetupPageState();
}

class _PatientSetupPageState extends ConsumerState<PatientSetupPage> {
  final _dobCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _dobCtrl.dispose();
    _diagnosisCtrl.dispose();
    _allergiesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).updateOnboardingProfile(
        dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
        primaryDiagnosis: _diagnosisCtrl.text.trim().isEmpty ? null : _diagnosisCtrl.text.trim(),
        allergies: _allergiesCtrl.text.trim().isEmpty
            ? null
            : _allergiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        medicalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _error = e.toString().contains('Connection refused')
              ? l10n.errorConnectionRefused
              : 'Không lưu được thông tin, vui lòng thử lại';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: VitalisColors.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Bỏ qua', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.medical_information_outlined, color: VitalisColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Thông tin y tế',
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Giúp MedIntel hỗ trợ bạn tốt hơn (có thể bổ sung sau)',
                    style: text.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: VitalisColors.surfaceContainerLowest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _dobCtrl,
                        keyboardType: TextInputType.datetime,
                        style: const TextStyle(color: VitalisColors.onSurface),
                        decoration: _lineDecor('Ngày sinh (YYYY-MM-DD)', Icons.cake_outlined),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _diagnosisCtrl,
                        style: const TextStyle(color: VitalisColors.onSurface),
                        decoration: _lineDecor('Bệnh nền chính', Icons.healing_outlined),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _allergiesCtrl,
                        style: const TextStyle(color: VitalisColors.onSurface),
                        decoration: _lineDecor('Dị ứng (phân cách bằng dấu phẩy)', Icons.warning_amber_outlined),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: VitalisColors.onSurface),
                        decoration: _lineDecor('Ghi chú y tế khác', Icons.notes_outlined),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: text.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: VitalisColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(l10n.patientSetupNext),
                                    const SizedBox(width: 8),
                                    Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.9)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _lineDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: VitalisColors.onSurfaceVariant),
      labelStyle: const TextStyle(color: VitalisColors.onSurfaceVariant),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: VitalisColors.outlineVariantBase.withValues(alpha: 0.5)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: VitalisColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    );
  }
}
