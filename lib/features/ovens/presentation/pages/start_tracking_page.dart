import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../controllers/oven_controller.dart';
import '../widgets/live_clock_text.dart';
import '../widgets/section_card.dart';

class StartTrackingPage extends StatelessWidget {
  const StartTrackingPage({
    super.key,
    required this.controller,
    required this.selectedOven,
    required this.selectedTime,
    required this.hourController,
    required this.minuteController,
    required this.startTimeManuallyPicked,
    required this.onOvenChanged,
    required this.onPickStartTime,
    required this.onStartTracking,
    required this.ovenOptions,
  });

  final OvenController controller;
  final String selectedOven;
  final TimeOfDay selectedTime;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final bool startTimeManuallyPicked;
  final ValueChanged<String> onOvenChanged;
  final VoidCallback onPickStartTime;
  final VoidCallback onStartTracking;
  final List<String> ovenOptions;

  String _formatSelectedTime(TimeOfDay time) {
    final int hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String mm = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$mm $period';
  }

  Widget _panelLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _heroStatTile({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.85),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: AppColors.textSecondary,
            ),
      filled: true,
      fillColor: AppColors.surfaceAlt.withValues(alpha: 0.62),
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: AppColors.border.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildNoAvailableOvensState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceAlt.withValues(alpha: 0.90),
            AppColors.card.withValues(alpha: 0.90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.local_fire_department_rounded,
            size: 56,
            color: AppColors.warning,
          ),
          SizedBox(height: 16),
          Text(
            'All ovens are active',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'You cannot start a new tracking session right now. Stop or complete an active oven first, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSessionForm({
    required List<String> availableOvens,
    required String? safeSelectedOven,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEW OVEN SESSION',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 22),
        DropdownButtonFormField<String>(
          initialValue: safeSelectedOven,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textSecondary,
          borderRadius: BorderRadius.circular(20),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
          decoration: _inputDecoration(
            label: 'Select oven',
            icon: Icons.factory_outlined,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 26,
            ),
          ),
          items: availableOvens.map((oven) {
            return DropdownMenuItem<String>(
              value: oven,
              child: Text(
                oven,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onOvenChanged(value);
            }
          },
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceAlt.withValues(alpha: 0.90),
                AppColors.card.withValues(alpha: 0.90),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onPickStartTime,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _panelLabel('START TIME'),
                        const SizedBox(height: 12),
                        Text(
                          _formatSelectedTime(selectedTime),
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          startTimeManuallyPicked
                              ? 'Manual time selected'
                              : 'Using current live factory time',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: startTimeManuallyPicked
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: hourController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDecoration(
                  label: 'Hours',
                  icon: Icons.schedule_rounded,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
                decoration: _inputDecoration(
                  label: 'Minutes',
                  icon: Icons.timelapse_rounded,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStartTracking,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(68),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(
              Icons.play_arrow_rounded,
              size: 24,
            ),
            label: const Text(
              'START TRACKING',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueChecks = _dueChecksCount();

    final activeOvenNames = controller.ovens.map((e) => e.ovenName).toSet();
    final availableOvens = ovenOptions
        .where((oven) => !activeOvenNames.contains(oven))
        .toList();

    final hasAvailableOvens = availableOvens.isNotEmpty;
    final String? safeSelectedOven =
        hasAvailableOvens && availableOvens.contains(selectedOven)
            ? selectedOven
            : (hasAvailableOvens ? availableOvens.first : null);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF102240),
                    Color(0xFF111B31),
                    Color(0xFF0C1525),
                  ],
                ),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.95),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _panelLabel('LIVE FACTORY TIME'),
                  const SizedBox(height: 10),
                  LiveClockText(text: controller.liveClock),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _heroStatTile(
                        icon: Icons.local_fire_department_rounded,
                        label: 'ACTIVE OVENS',
                        value: '${controller.ovens.length}',
                        gradient: const [
                          Color(0xFF162743),
                          Color(0xFF102038),
                        ],
                      ),
                      const SizedBox(width: 12),
                      _heroStatTile(
                        icon: Icons.notifications_active_rounded,
                        label: 'DUE CHECKS',
                        value: '$dueChecks',
                        gradient: dueChecks > 0
                            ? const [
                                Color(0xFF3A1D28),
                                Color(0xFF251723),
                              ]
                            : const [
                                Color(0xFF162743),
                                Color(0xFF102038),
                              ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              child: hasAvailableOvens
                  ? _buildAvailableSessionForm(
                      availableOvens: availableOvens,
                      safeSelectedOven: safeSelectedOven,
                    )
                  : _buildNoAvailableOvensState(),
            ),
          ],
        ),
      ),
    );
  }

  int _dueChecksCount() {
    final nowMinute = controller.nowMinuteOfDay;
    int count = 0;

    for (final oven in controller.ovens) {
      for (final step in oven.steps) {
        if (!step.checked && nowMinute >= step.minuteOfDay) {
          count++;
        }
      }
    }

    return count;
  }
}