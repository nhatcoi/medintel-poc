import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vitalis_colors.dart';

class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo-like gradient layer
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [VitalisColors.primaryContainer, VitalisColors.primary],
              ),
            ),
          ),
          // Soft dark overlay to match mock mood
          Container(color: VitalisColors.secondary.withValues(alpha: 0.56)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'Join millions of people\nalready taking control of\ntheir meds',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/setup'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: VitalisColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('GET STARTED'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => context.go('/setup'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: text.bodyLarge?.copyWith(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: 'Log in',
                            style: text.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By proceeding, you agree to our Terms and that\nyou have read our Privacy Policy',
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
