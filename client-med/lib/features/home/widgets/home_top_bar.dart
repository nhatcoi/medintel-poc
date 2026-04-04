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
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarCircle(initial: initial),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: text.labelMedium?.copyWith(
                    color: VitalisColors.neutral,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _firstName(userName),
                  style: text.titleLarge?.copyWith(
                    color: VitalisColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _IconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 4),
          _IconButton(
            icon: Icons.settings_outlined,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'CHÀO BUỔI SÁNG';
    if (hour < 18) return 'CHÀO BUỔI CHIỀU';
    return 'CHÀO BUỔI TỐI';
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.last;
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VitalisColors.primary, VitalisColors.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: VitalisColors.primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
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
