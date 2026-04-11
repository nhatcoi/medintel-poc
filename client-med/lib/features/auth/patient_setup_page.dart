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
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) return;

    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).completeSetup(
        fullName: '$first $last',
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canNext = !_loading &&
        _firstNameCtrl.text.trim().isNotEmpty &&
        _lastNameCtrl.text.trim().isNotEmpty;

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
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/welcome');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                    child: const Icon(Icons.assignment_outlined, color: VitalisColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Let's get to know you better!\nWhat's your name?",
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _firstNameCtrl,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: VitalisColors.onSurface),
                        decoration: _lineDecor('First name*'),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _lastNameCtrl,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => canNext ? _submit() : null,
                        style: const TextStyle(color: VitalisColors.onSurface),
                        decoration: _lineDecor('Last name*'),
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
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: canNext ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: canNext
                                ? VitalisColors.primary
                                : VitalisColors.outlineVariantBase.withValues(alpha: 0.5),
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
                                    const Text('Next'),
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

  InputDecoration _lineDecor(String label) {
    return InputDecoration(
      labelText: label,
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
