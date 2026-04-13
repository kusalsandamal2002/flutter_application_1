import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/oven_item.dart';
import '../../data/models/sensor_step.dart';
import '../controllers/oven_controller.dart';
import '../widgets/section_card.dart';

class DueChecksPage extends StatelessWidget {
  const DueChecksPage({
    super.key,
    required this.controller,
    required this.onCheckStep,
  });

  final OvenController controller;
  final void Function({
    required String sessionId,
    required String stepId,
  }) onCheckStep;

  List<_DueCheckItem> _collectDueChecks() {
    final nowMinute = controller.nowMinuteOfDay;
    final List<_DueCheckItem> items = [];

    for (final oven in controller.ovens) {
      for (final step in oven.steps) {
        if (!step.checked && nowMinute >= step.minuteOfDay) {
          items.add(
            _DueCheckItem(
              oven: oven,
              step: step,
            ),
          );
        }
      }
    }

    items.sort((a, b) => a.step.minuteOfDay.compareTo(b.step.minuteOfDay));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final dueChecks = _collectDueChecks();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: dueChecks.isEmpty
                      ? AppColors.surfaceAlt.withValues(alpha: 0.55)
                      : AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: dueChecks.isEmpty
                        ? AppColors.border
                        : AppColors.danger.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  dueChecks.isEmpty
                      ? Icons.task_alt_rounded
                      : Icons.notifications_active_rounded,
                  color:
                      dueChecks.isEmpty ? AppColors.primary : AppColors.danger,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHECKS NEEDING ATTENTION',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Operator action queue for due sensor confirmations.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: dueChecks.isEmpty
                      ? AppColors.surfaceAlt.withValues(alpha: 0.55)
                      : AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: dueChecks.isEmpty
                        ? AppColors.border
                        : AppColors.danger.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '${dueChecks.length} DUE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: dueChecks.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (dueChecks.isEmpty)
          const SectionCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No due sensor checks right now.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...dueChecks.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.card,
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.oven.ovenName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sensor check due at ${item.step.display}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.surfaceAlt.withValues(alpha: 0.48),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STATUS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Pending Check',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 164,
                          child: FilledButton.icon(
                            onPressed: () {
                              onCheckStep(
                                sessionId: item.oven.sessionId,
                                stepId: item.step.id,
                              );
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text(
                              'CHECK NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DueCheckItem {
  const _DueCheckItem({
    required this.oven,
    required this.step,
  });

  final OvenItem oven;
  final SensorStep step;
}