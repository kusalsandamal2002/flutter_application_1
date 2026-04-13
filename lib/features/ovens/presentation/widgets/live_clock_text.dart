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
        horizontal: 22,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        // 🔥 glass + gradient
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceAlt.withValues(alpha: 0.95),
            AppColors.card.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
        ),

        // 🔥 premium glow
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 22,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 44, // 🔥 bigger
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}