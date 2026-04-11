import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Thanh tiêu đề Home: avatar + lời chào + nút cài đặt.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.userName,
    this.onSettingsTap,
  });

  final String userName;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _BrandDot(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'MedIntel',
              style: text.titleLarge?.copyWith(
                color: VitalisColors.primary,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _IconButton(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }

}

class _BrandDot extends StatelessWidget {
  const _BrandDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2D333A),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: Colors.white, size: 16),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 24, color: VitalisColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
