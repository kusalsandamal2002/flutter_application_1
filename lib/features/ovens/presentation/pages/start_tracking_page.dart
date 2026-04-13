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
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _panelLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
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
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: AppColors.surfaceAlt.withValues(alpha: 0.50),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 124),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _panelLabel('LIVE FACTORY TIME'),
                      const SizedBox(height: 10),
                      LiveClockText(text: controller.liveClock),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _statTile(
                            icon: Icons.local_fire_department_rounded,
                            label: 'ACTIVE OVENS',
                            value: '${controller.ovens.length}',
                          ),
                          const SizedBox(width: 12),
                          _statTile(
                            icon: Icons.notifications_active_rounded,
                            label: 'DUE CHECKS',
                            value: '${_dueChecksCount()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEW OVEN SESSION',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Industrial operator layout with fast input controls.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<String>(
                        initialValue: selectedOven,
                        decoration: _inputDecoration(
                          label: 'Select oven',
                          icon: Icons.factory_outlined,
                        ),
                        items: ovenOptions.map((oven) {
                          return DropdownMenuItem<String>(
                            value: oven,
                            child: Text(
                              oven,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          onOvenChanged(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _panelLabel('START TIME'),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatSelectedTime(selectedTime),
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    startTimeManuallyPicked
                                        ? 'Manual time selected'
                                        : 'Using current live time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: startTimeManuallyPicked
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonalIcon(
                              onPressed: onPickStartTime,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(126, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.access_time_rounded),
                              label: Text(
                                startTimeManuallyPicked ? 'CHANGE' : 'PICK',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
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
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: _inputDecoration(
                                label: 'Hours',
                                icon: Icons.schedule_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: minuteController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: _inputDecoration(
                                label: 'Minutes',
                                icon: Icons.timelapse_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Only the visual style is upgraded. All oven tracking functions remain unchanged.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.26),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStartTracking,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    'START TRACKING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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