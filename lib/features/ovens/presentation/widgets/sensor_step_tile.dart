import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/sensor_step.dart';

class SensorStepTile extends StatelessWidget {
  const SensorStepTile({
    super.key,
    required this.step,
    required this.onCheck,
  });

  final SensorStep step;
  final VoidCallback onCheck;

  int _nowMinuteOfDay() {
    final TimeOfDay now = TimeOfDay.now();
    return now.hour * 60 + now.minute;
  }

  bool _isDue() {
    return _nowMinuteOfDay() >= step.minuteOfDay;
  }

  Color _statusColor() {
    if (step.checked) {
      return AppColors.success;
    }

    if (_isDue()) {
      return AppColors.danger;
    }

    return AppColors.textSecondary;
  }

  String _statusText() {
    if (step.checked) {
      return 'Checked';
    }

    if (_isDue()) {
      return 'Pending';
    }

    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _statusColor();
    final bool isDue = _isDue();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceAlt.withValues(alpha: 0.9),
            AppColors.card.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: step.checked
              ? AppColors.success.withValues(alpha: 0.5)
              : isDue
                  ? AppColors.danger.withValues(alpha: 0.5)
                  : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: step.checked
                ? AppColors.success.withValues(alpha: 0.15)
                : isDue
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: step.checked
                  ? AppColors.success.withValues(alpha: 0.15)
                  : isDue
                      ? AppColors.danger.withValues(alpha: 0.15)
                      : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.checked
                  ? Icons.check
                  : isDue
                      ? Icons.priority_high
                      : Icons.schedule,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.display,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusText(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!step.checked && isDue)
            FilledButton(
              onPressed: onCheck,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('CHECK'),
            ),
        ],
      ),
    );
  }
}