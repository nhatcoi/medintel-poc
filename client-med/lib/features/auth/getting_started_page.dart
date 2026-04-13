import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/vitalis_colors.dart';
import '../../providers/providers.dart';

class GettingStartedPage extends ConsumerStatefulWidget {
  const GettingStartedPage({super.key});

  @override
  ConsumerState<GettingStartedPage> createState() => _GettingStartedPageState();
}

class _GettingStartedPageState extends ConsumerState<GettingStartedPage> {
  bool _isLogin = false;
  bool _loading = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_loading) return false;
    if (_phoneCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) return false;
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await ref.read(authProvider.notifier).loginPhone(
              phoneNumber: _phoneCtrl.text.trim(),
              password: _passCtrl.text.trim(),
            );
      } else {
        await ref.read(authProvider.notifier).registerPhone(
              fullName: _nameCtrl.text.trim(),
              phoneNumber: _phoneCtrl.text.trim(),
              password: _passCtrl.text.trim(),
            );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('400')) {
          msg = 'Số điện thoại đã được đăng ký';
        } else if (msg.contains('401')) {
          msg = 'Sai số điện thoại hoặc mật khẩu';
        } else if (msg.contains('Connection refused')) {
          msg = AppLocalizations.of(context).errorConnectionRefused;
        } else {
          msg = 'Đã xảy ra lỗi, vui lòng thử lại';
        }
        setState(() { _error = msg; _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [VitalisColors.primaryContainer, VitalisColors.primary],
              ),
            ),
          ),
          Container(color: VitalisColors.secondary.withValues(alpha: 0.56)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    l10n.gettingStartedHeadline,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Toggle register / login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TabChip(
                        label: 'Đăng ký',
                        isActive: !_isLogin,
                        onTap: () => setState(() { _isLogin = false; _error = null; }),
                      ),
                      const SizedBox(width: 12),
                      _TabChip(
                        label: 'Đăng nhập',
                        isActive: _isLogin,
                        onTap: () => setState(() { _isLogin = true; _error = null; }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Name field (register only)
                  if (!_isLogin) ...[
                    _InputField(
                      controller: _nameCtrl,
                      label: 'Họ và tên',
                      icon: Icons.person_outline,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                  ],

                  _InputField(
                    controller: _phoneCtrl,
                    label: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  _InputField(
                    controller: _passCtrl,
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePass,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white60,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: Colors.redAccent.shade100),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: VitalisColors.primary,
                        disabledBackgroundColor: Colors.white30,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'Đăng nhập' : l10n.gettingStartedCta),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.gettingStartedLegal,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: Colors.white60,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isActive ? Colors.white : Colors.white12,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isActive ? VitalisColors.primary : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white60, size: 20),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
