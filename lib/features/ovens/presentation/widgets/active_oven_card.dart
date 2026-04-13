import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/oven_item.dart';
import 'sensor_step_tile.dart';

class ActiveOvenCard extends StatefulWidget {
  const ActiveOvenCard({
    super.key,
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
  State<ActiveOvenCard> createState() => _ActiveOvenCardState();
}

class _ActiveOvenCardState extends State<ActiveOvenCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _alertController;
  late final Animation<double> _buttonOpacity;
  late final Animation<double> _buttonScale;
  late final Animation<double> _stripOpacity;

  @override
  void initState() {
    super.initState();

    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _buttonOpacity = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _alertController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonScale = Tween<double>(begin: 0.985, end: 1.02).animate(
      CurvedAnimation(
        parent: _alertController,
        curve: Curves.easeInOut,
      ),
    );

    _stripOpacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _alertController,
        curve: Curves.easeInOut,
      ),
    );

    _syncAlertState();
  }

  @override
  void didUpdateWidget(covariant ActiveOvenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAlertState();
  }

  void _syncAlertState() {
    if (_isFinished()) {
      if (!_alertController.isAnimating) {
        _alertController.repeat(reverse: true);
      }
    } else {
      _alertController.stop();
      _alertController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _alertController.dispose();
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

    if (widget.oven.totalMinutes <= 0) {
      return 0;
    }

    if (start == end) {
      return widget.oven.totalMinutes;
    }

    if (start < end) {
      if (now <= start) return 0;
      if (now >= end) return widget.oven.totalMinutes;
      return now - start;
    }

    final wrappedNow = now < start ? now + (24 * 60) : now;
    final wrappedEnd = end + (24 * 60);

    if (wrappedNow <= start) return 0;
    if (wrappedNow >= wrappedEnd) return widget.oven.totalMinutes;
    return wrappedNow - start;
  }

  double _timeProgress() {
    final elapsed = _elapsedMinutes().clamp(0, widget.oven.totalMinutes);
    if (widget.oven.totalMinutes <= 0) {
      return 0;
    }
    return elapsed / widget.oven.totalMinutes;
  }

  bool _isFinished() {
    return _elapsedMinutes() >= widget.oven.totalMinutes;
  }

  bool _isStepDue(int stepMinuteOfDay) {
    final elapsed = _elapsedMinutes();
    final stepOffset = _normalizeMinuteFromStart(stepMinuteOfDay);
    return elapsed >= stepOffset;
  }

  Color _stepColor({
    required bool checked,
    required bool isDue,
  }) {
    if (checked) return AppColors.successGreen;
    if (isDue) return AppColors.danger;
    return AppColors.warning;
  }

  String _stepStatusText({
    required bool checked,
    required bool isDue,
  }) {
    if (checked) return 'Checked';
    if (isDue) return 'Pending Check';
    return 'Upcoming';
  }

  Widget _miniInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isFinished,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isFinished
              ? AppColors.danger.withValues(alpha: 0.08)
              : AppColors.surfaceAlt.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFinished
                ? AppColors.danger.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isFinished ? AppColors.danger : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isFinished ? AppColors.danger : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }

  Widget _buildFinishedActionButton() {
    return FadeTransition(
      opacity: _buttonOpacity,
      child: ScaleTransition(
        scale: _buttonScale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.32),
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: widget.onClose,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.inventory_2_outlined,
              size: 22,
            ),
            label: const Text(
              'REMOVE FROM OVEN',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowStrip() {
    return FadeTransition(
      opacity: _stripOpacity,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          gradient: LinearGradient(
            colors: [
              AppColors.danger.withValues(alpha: 0.00),
              AppColors.danger.withValues(alpha: 0.55),
              const Color(0xFFFFB3B3).withValues(alpha: 0.95),
              AppColors.danger.withValues(alpha: 0.55),
              AppColors.danger.withValues(alpha: 0.00),
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.30),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFFFFB3B3).withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = widget.oven.steps.where((e) => e.checked).length;
    final totalSteps = widget.oven.steps.length;
    final progress = _timeProgress();
    final progressPercent = (progress * 100).round();
    final elapsedMinutes = _elapsedMinutes().clamp(0, widget.oven.totalMinutes);
    final remainingMinutes =
        (widget.oven.totalMinutes - elapsedMinutes).clamp(0, widget.oven.totalMinutes);
    final isFinished = _isFinished();

    final List<Color> cardGradient = isFinished
        ? [
            const Color(0xFF2A1218),
            const Color(0xFF1B1015),
          ]
        : [
            AppColors.card,
            AppColors.surface,
          ];

    final Color borderColor = isFinished
        ? AppColors.danger.withValues(alpha: 0.28)
        : AppColors.border.withValues(alpha: 0.9);

    final Color shadowColor = isFinished
        ? AppColors.danger.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.24);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor,
          width: isFinished ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isFinished ? 26 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            if (isFinished) _buildGlowStrip(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFinished) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notification_important_rounded,
                              color: AppColors.danger,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Oven completed',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Remove product from oven and close this session.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isFinished
                              ? AppColors.danger.withValues(alpha: 0.16)
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFinished
                                ? AppColors.danger.withValues(alpha: 0.24)
                                : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          isFinished
                              ? Icons.warning_amber_rounded
                              : Icons.local_fire_department_rounded,
                          color: isFinished ? AppColors.danger : AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.oven.ovenName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFinished
                                  ? 'Completed - waiting for operator confirmation'
                                  : 'Active tracking session',
                              style: TextStyle(
                                color: isFinished
                                    ? AppColors.danger
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isFinished) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Close'),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (isFinished) ...[
                    _buildFinishedActionButton(),
                    const SizedBox(height: 18),
                  ],

                  Row(
                    children: [
                      _miniInfoCard(
                        icon: Icons.login_rounded,
                        label: 'IN TIME',
                        value: widget.oven.startDisplay,
                        isFinished: isFinished,
                      ),
                      const SizedBox(width: 10),
                      _miniInfoCard(
                        icon: Icons.logout_rounded,
                        label: 'OUT TIME',
                        value: widget.oven.outDisplay,
                        isFinished: isFinished,
                      ),
                      const SizedBox(width: 10),
                      _miniInfoCard(
                        icon: Icons.timelapse_rounded,
                        label: 'DURATION',
                        value: '${widget.oven.totalMinutes} min',
                        isFinished: isFinished,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _sectionTitle(
                    'Progress',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isFinished
                            ? AppColors.danger.withValues(alpha: 0.14)
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isFinished
                              ? AppColors.danger.withValues(alpha: 0.24)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$progressPercent%',
                        style: TextStyle(
                          color: isFinished ? AppColors.danger : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      const markerSize = 22.0;

                      return SizedBox(
                        height: 50,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 18,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isFinished
                                        ? AppColors.danger.withValues(alpha: 0.18)
                                        : AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 18,
                              child: Container(
                                width: barWidth * progress,
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: isFinished
                                        ? const [
                                            AppColors.danger,
                                            Color(0xFFFF9D9D),
                                          ]
                                        : const [
                                            AppColors.primary,
                                            Color(0xFFFFB3B3),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isFinished
                                              ? AppColors.danger
                                              : AppColors.primary)
                                          .withValues(alpha: 0.30),
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

                              final left = (barWidth * ratio) - (markerSize / 2);
                              final isDue = _isStepDue(step.minuteOfDay);
                              final markerColor = _stepColor(
                                checked: step.checked,
                                isDue: isDue,
                              );

                              return Positioned(
                                left: left.clamp(0.0, barWidth - markerSize),
                                top: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    if (!step.checked && isDue) {
                                      widget.onCheckStep(step.id);
                                    }
                                  },
                                  child: Tooltip(
                                    message:
                                        '${step.display} • ${_stepStatusText(checked: step.checked, isDue: isDue)}',
                                    child: Container(
                                      width: markerSize,
                                      height: markerSize,
                                      decoration: BoxDecoration(
                                        color: markerColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: markerColor.withValues(
                                              alpha: 0.40,
                                            ),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        step.checked
                                            ? Icons.check
                                            : isDue
                                                ? Icons.priority_high_rounded
                                                : Icons.schedule_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isFinished
                          ? AppColors.danger.withValues(alpha: 0.07)
                          : AppColors.surfaceAlt.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFinished
                            ? AppColors.danger.withValues(alpha: 0.18)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Elapsed',
                            value: '$elapsedMinutes min',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: isFinished
                              ? AppColors.danger.withValues(alpha: 0.14)
                              : AppColors.border,
                        ),
                        Expanded(
                          child: _MetricTile(
                            label: 'Remaining',
                            value: '$remainingMinutes min',
                            align: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: isFinished
                              ? AppColors.danger.withValues(alpha: 0.14)
                              : AppColors.border,
                        ),
                        Expanded(
                          child: _MetricTile(
                            label: 'Checks',
                            value: '$checkedCount / $totalSteps',
                            align: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _sectionTitle(
                    'Sensor Checks',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$checkedCount / $totalSteps completed',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 12),

                  if (widget.oven.steps.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        isFinished
                            ? 'No sensor checks for this session. Oven is ready to be removed.'
                            : 'No sensor checks for this session.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ...widget.oven.steps.map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SensorStepTile(
                          step: step,
                          onCheck: () => widget.onCheckStep(step.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.align = TextAlign.start,
  });

  final String label;
  final String value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.start
          ? CrossAxisAlignment.start
          : align == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: align,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: align,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}