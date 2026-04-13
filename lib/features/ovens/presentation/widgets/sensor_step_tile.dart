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
    final now = TimeOfDay.now();
    return now.hour * 60 + now.minute;
  }

  bool _isDue() {
    return _nowMinuteOfDay() >= step.minuteOfDay;
  }

  Color _statusColor() {
    if (step.checked) {
      return AppColors.successGreen;
    }
    if (_isDue()) {
      return AppColors.danger;
    }
    return AppColors.warning;
  }

  String _statusText() {
    if (step.checked) {
      return 'Checked';
    }
    if (_isDue()) {
      return 'Pending Check';
    }
    return 'Upcoming';
  }

  IconData _statusIcon() {
    if (step.checked) {
      return Icons.check_circle;
    }
    if (_isDue()) {
      return Icons.notification_important_rounded;
    }
    return Icons.schedule;
  }

  // ✅ FIX: label fallback
  String _stepLabel() {
    return step.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final isDue = _isDue();

    return InkWell(
      onTap: (!step.checked && isDue) ? onCheck : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(_statusIcon(), color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepLabel(), // ✅ FIXED
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusText(),
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!step.checked && isDue)
              ElevatedButton(
                onPressed: onCheck,
                child: const Text('Check'),
              ),
          ],
        ),
      ),
    );
  }
}