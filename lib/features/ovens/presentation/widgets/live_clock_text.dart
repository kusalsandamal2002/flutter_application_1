import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class LiveClockText extends StatelessWidget {
  const LiveClockText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}