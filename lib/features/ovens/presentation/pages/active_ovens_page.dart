import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/oven_item.dart';
import '../../data/models/sensor_step.dart';
import '../controllers/oven_controller.dart';

class ActiveOvensPage extends StatelessWidget {
  const ActiveOvensPage({
    super.key,
    required this.controller,
    this.onCloseOven,
    this.onCheckStep,
  });

  final OvenController controller;
  final Future<void> Function(String sessionId)? onCloseOven;
  final void Function({
    required String sessionId,
    required String stepId,
  })? onCheckStep;

  @override
  Widget build(BuildContext context) {
    final activeOvens = controller.ovens;

    return Scaffold(
      backgroundColor: const Color(0xFF031522),
      body: SafeArea(
        child: activeOvens.isEmpty
            ? const _EmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _HeaderCard(count: activeOvens.length),
                  const SizedBox(height: 16),
                  ...activeOvens.map(
                    (oven) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _ActiveOvenCard(
                        oven: oven,
                        nowMinuteOfDay: controller.nowMinuteOfDay,
                        onClose: () async {
                          await onCloseOven?.call(oven.sessionId);
                        },
                        onCheckStep: (stepId) {
                          onCheckStep?.call(
                            sessionId: oven.sessionId,
                            stepId: stepId,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16283B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Running oven sessions',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Text(
              '$count active',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16283B),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              color: Colors.white54,
              size: 42,
            ),
            SizedBox(height: 14),
            Text(
              'No active ovens',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no running oven sessions right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOvenCard extends StatefulWidget {
  const _ActiveOvenCard({
    required this.oven,
    required this.nowMinuteOfDay,
    required this.onClose,
    required this.onCheckStep,
  });

  final OvenItem oven;
  final int nowMinuteOfDay;
  final VoidCallback onClose;
  final void Function(String stepId) onCheckStep;

  @override
  State<_ActiveOvenCard> createState() => _ActiveOvenCardState();
}

class _ActiveOvenCardState extends State<_ActiveOvenCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _actionScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseScale = Tween<double>(begin: 0.90, end: 1.35).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    _pulseOpacity = Tween<double>(begin: 0.36, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    _actionScale = Tween<double>(begin: 0.985, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _ActiveOvenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (_hasAnyDueUncheckedStep() || _isFinished()) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _normalizeMinuteFromStart(int minuteOfDay) {
    if (minuteOfDay >= widget.oven.startMinuteOfDay) {
      return minuteOfDay - widget.oven.startMinuteOfDay;
    }
    return (24 * 60 - widget.oven.startMinuteOfDay) + minuteOfDay;
  }

  int _elapsedMinutes() {
    final start = widget.oven.startMinuteOfDay;
    final end = widget.oven.endMinuteOfDayRaw;
    final now = widget.nowMinuteOfDay;
    final total = widget.oven.totalMinutes;

    if (total <= 0) {
      return 0;
    }

    if (start == end) {
      return total;
    }

    if (start < end) {
      if (now <= start) {
        return 0;
      }
      if (now >= end) {
        return total;
      }
      return now - start;
    }

    final wrappedNow = now < start ? now + (24 * 60) : now;
    final wrappedEnd = end + (24 * 60);

    if (wrappedNow <= start) {
      return 0;
    }
    if (wrappedNow >= wrappedEnd) {
      return total;
    }

    return wrappedNow - start;
  }

  double _progress() {
    if (widget.oven.totalMinutes <= 0) {
      return 0;
    }

    final elapsed = _elapsedMinutes().clamp(0, widget.oven.totalMinutes);
    return elapsed / widget.oven.totalMinutes;
  }

  bool _isFinished() {
    return _elapsedMinutes() >= widget.oven.totalMinutes;
  }

  bool _isStepDue(SensorStep step) {
    if (step.checked) {
      return false;
    }

    final elapsed = _elapsedMinutes();
    final stepOffset = _normalizeMinuteFromStart(step.minuteOfDay);
    return elapsed >= stepOffset;
  }

  bool _hasAnyDueUncheckedStep() {
    return widget.oven.steps.any(_isStepDue);
  }

  bool _allSensorChecksCompleted() {
    if (widget.oven.steps.isEmpty) {
      return true;
    }
    return widget.oven.steps.every((step) => step.checked);
  }

  SensorStep? _nextPendingStep() {
    final pending = widget.oven.steps.where((step) => !step.checked).toList();
    if (pending.isEmpty) {
      return null;
    }

    pending.sort(
      (a, b) => _normalizeMinuteFromStart(a.minuteOfDay).compareTo(
        _normalizeMinuteFromStart(b.minuteOfDay),
      ),
    );

    return pending.first;
  }

  List<SensorStep> _sortedSteps() {
    final result = [...widget.oven.steps];
    result.sort(
      (a, b) => _normalizeMinuteFromStart(a.minuteOfDay).compareTo(
        _normalizeMinuteFromStart(b.minuteOfDay),
      ),
    );
    return result;
  }

  Color _markerColor(SensorStep step) {
    if (step.checked) {
      return AppColors.successGreen;
    }
    if (_isStepDue(step)) {
      return AppColors.danger;
    }
    return AppColors.warning;
  }

  IconData _markerIcon(SensorStep step) {
    if (step.checked) {
      return Icons.check;
    }
    if (_isStepDue(step)) {
      return Icons.priority_high_rounded;
    }
    return Icons.circle;
  }

  String _stepStatusText(SensorStep step) {
    if (step.checked) {
      return 'Checked';
    }
    if (_isStepDue(step)) {
      return 'Pending Check';
    }
    return 'Upcoming';
  }

  _ActionState _actionState() {
    if (_isFinished()) {
      return _ActionState.removeNow;
    }

    final dueSteps = widget.oven.steps.where(_isStepDue).toList();
    if (dueSteps.isNotEmpty) {
      return _ActionState.checkNow;
    }

    if (_allSensorChecksCompleted()) {
      return _ActionState.waitingOutTime;
    }

    return _ActionState.upcomingCheck;
  }

  Widget _buildTopInfoBox({
    required String title,
    required String value,
    required bool emphasize,
    IconData? icon,
  }) {
    final Color titleColor = emphasize ? AppColors.danger : Colors.white38;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF23364A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: emphasize
                ? AppColors.danger.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 11,
                    color: titleColor,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTimeline() {
    final progress = _progress().clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();
    final isFinished = _isFinished();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isFinished
                    ? AppColors.danger.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isFinished
                      ? AppColors.danger.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Text(
                '$progressPercent%',
                style: TextStyle(
                  color: isFinished ? AppColors.danger : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const barTop = 24.0;
            const barHeight = 8.0;
            const markerSize = 20.0;
            const endMarkerSize = 30.0;

            return SizedBox(
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: barTop,
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: barTop,
                    child: Container(
                      width: width * progress,
                      height: barHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: isFinished ? AppColors.danger : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (isFinished
                                    ? AppColors.danger
                                    : Colors.redAccent)
                                .withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...widget.oven.steps.map((step) {
                    final stepOffset =
                        _normalizeMinuteFromStart(step.minuteOfDay);
                    final ratio = widget.oven.totalMinutes <= 0
                        ? 0.0
                        : (stepOffset / widget.oven.totalMinutes)
                            .clamp(0.0, 1.0);
                    final left = ((width * ratio) - (markerSize / 2))
                        .clamp(0.0, width - markerSize);
                    final color = _markerColor(step);
                    final isDue = _isStepDue(step);

                    return Positioned(
                      left: left,
                      top: barTop - 6,
                      child: Tooltip(
                        message: '${step.display} • ${_stepStatusText(step)}',
                        child: GestureDetector(
                          onTap: () {
                            if (!step.checked && isDue) {
                              widget.onCheckStep(step.id);
                            }
                          },
                          child: SizedBox(
                            width: markerSize,
                            height: markerSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isDue && !step.checked)
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, _) {
                                      return Transform.scale(
                                        scale: _pulseScale.value,
                                        child: Container(
                                          width: markerSize,
                                          height: markerSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color.withValues(
                                              alpha: _pulseOpacity.value,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                Container(
                                  width: markerSize,
                                  height: markerSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.30),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _markerIcon(step),
                                    size: step.checked || isDue ? 12 : 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    left: width - endMarkerSize,
                    top: barTop - ((endMarkerSize - barHeight) / 2),
                    child: Tooltip(
                      message: isFinished
                          ? 'Remove from oven now'
                          : 'Remove from oven at ${widget.oven.outDisplay}',
                      child: SizedBox(
                        width: endMarkerSize,
                        height: endMarkerSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isFinished)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return Transform.scale(
                                    scale: _pulseScale.value,
                                    child: Container(
                                      width: endMarkerSize,
                                      height: endMarkerSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.danger.withValues(
                                          alpha: _pulseOpacity.value,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Container(
                              width: endMarkerSize,
                              height: endMarkerSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isFinished
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF7D7D),
                                          AppColors.danger,
                                        ],
                                      )
                                    : const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFB86A),
                                          Color(0xFFFF8A3D),
                                        ],
                                      ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.6,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isFinished
                                            ? AppColors.danger
                                            : const Color(0xFFFFA24D))
                                        .withValues(alpha: 0.40),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFinished
                                    ? Icons.inventory_2_outlined
                                    : Icons.outbox_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(SensorStep step) {
    final isDue = _isStepDue(step);
    final isChecked = step.checked;

    final Color color;
    final String text;
    final IconData icon;

    if (isChecked) {
      color = AppColors.successGreen;
      text = 'CHECKED';
      icon = Icons.check_circle;
    } else if (isDue) {
      color = AppColors.danger;
      text = 'CHECK NOW';
      icon = Icons.notifications_active;
    } else {
      color = AppColors.warning;
      text = 'UPCOMING';
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final state = _actionState();
    final isRemove = state == _ActionState.removeNow;
    final isCheckNow = state == _ActionState.checkNow;

    if (isCheckNow) {
      final dueSteps = _sortedSteps()
          .where((step) => !step.checked && _isStepDue(step))
          .toList();

      final targetStep = dueSteps.isNotEmpty ? dueSteps.first : null;
      if (targetStep != null) {
        return ScaleTransition(
          scale: _actionScale,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => widget.onCheckStep(targetStep.id),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.sensors_rounded, size: 18),
              label: const Text(
                'CHECK SENSOR NOW',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (isRemove) {
      return ScaleTransition(
        scale: _actionScale,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onClose,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text(
              'REMOVE FROM OVEN',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      );
    }

    final buttonText = _allSensorChecksCompleted()
        ? 'WAITING FOR OUT TIME'
        : 'CLOSE SESSION';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onClose,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: Colors.white70,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          _allSensorChecksCompleted()
              ? Icons.schedule_rounded
              : Icons.check_circle_outline,
          size: 18,
        ),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _sortedSteps();
    final completedCount = steps.where((step) => step.checked).length;
    final dueCount = steps.where(_isStepDue).length;
    final isFinished = _isFinished();
    final nextPendingStep = _nextPendingStep();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFinished
              ? const [
                  Color(0xFF241217),
                  Color(0xFF190F13),
                ]
              : const [
                  Color(0xFF18304F),
                  Color(0xFF102642),
                ],
        ),
        border: Border.all(
          color: isFinished
              ? AppColors.danger.withValues(alpha: 0.50)
              : Colors.white.withValues(alpha: 0.08),
          width: isFinished ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isFinished
                ? AppColors.danger.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.22),
            blurRadius: isFinished ? 22 : 18,
            spreadRadius: isFinished ? 1 : 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFinished)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.26),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Time completed. Remove product from oven.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFinished
                        ? AppColors.danger.withValues(alpha: 0.20)
                        : Colors.redAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFinished
                          ? AppColors.danger.withValues(alpha: 0.24)
                          : Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Icon(
                    isFinished
                        ? Icons.warning_amber_rounded
                        : Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.oven.ovenName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFinished
                              ? 'Completed • waiting for operator action'
                              : 'Active tracking session',
                          style: TextStyle(
                            color:
                                isFinished ? AppColors.danger : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTopInfoBox(
                  title: 'IN TIME',
                  value: widget.oven.startDisplay,
                  emphasize: false,
                  icon: Icons.login_rounded,
                ),
                const SizedBox(width: 10),
                _buildTopInfoBox(
                  title: 'OUT TIME',
                  value: widget.oven.outDisplay,
                  emphasize: isFinished,
                  icon: Icons.logout_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildProgressTimeline(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sensor Checks',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: dueCount > 0
                        ? AppColors.danger.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: dueCount > 0
                          ? AppColors.danger.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Text(
                    dueCount > 0
                        ? '$dueCount due / $completedCount done'
                        : '$completedCount / ${steps.length} done',
                    style: TextStyle(
                      color: dueCount > 0 ? AppColors.danger : Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (steps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF203451),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'No sensor checks for this session.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            else
              ...steps.map(
                (step) {
                  final isDue = _isStepDue(step);
                  final done = step.checked;
                  final isNextPending = !done && nextPendingStep?.id == step.id;

                  final borderColor = done
                      ? Colors.green.withValues(alpha: 0.32)
                      : isDue
                          ? AppColors.danger.withValues(alpha: 0.42)
                          : isNextPending
                              ? AppColors.warning.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.06);

                  final backgroundColor = done
                      ? const Color(0xFF1B3C3B)
                      : isDue
                          ? const Color(0xFF3A2024)
                          : isNextPending
                              ? const Color(0xFF3A3221)
                              : const Color(0xFF1E334F);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      minLeadingWidth: 20,
                      onTap: (!done && isDue)
                          ? () => widget.onCheckStep(step.id)
                          : null,
                      leading: Icon(
                        done
                            ? Icons.check_circle
                            : isDue
                                ? Icons.notifications_active
                                : Icons.radio_button_unchecked,
                        color: done
                            ? Colors.greenAccent
                            : isDue
                                ? AppColors.danger
                                : Colors.white54,
                        size: 20,
                      ),
                      title: Text(
                        step.display,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildStatusBadge(step),
                      ),
                      trailing: done
                          ? const Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                              size: 18,
                            )
                          : isDue
                              ? FilledButton(
                                  onPressed: () => widget.onCheckStep(step.id),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(112, 42),
                                    backgroundColor: AppColors.danger,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'CHECK NOW',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 14),
            _buildPrimaryButton(),
          ],
        ),
      ),
    );
  }
}

enum _ActionState {
  checkNow,
  upcomingCheck,
  waitingOutTime,
  removeNow,
}