import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/system_tone_option.dart';
import '../controllers/oven_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.controller,
  });

  final OvenController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loadingTones = true;
  String? _toneLoadError;

  List<SystemToneOption> _mainAlarmTones = const [];
  List<SystemToneOption> _sensorAlertTones = const [];

  @override
  void initState() {
    super.initState();
    _loadTones();
  }

  Future<void> _loadTones() async {
    setState(() {
      _loadingTones = true;
      _toneLoadError = null;
    });

    try {
      await widget.controller.init();
      final mainAlarmTones = await widget.controller.getMainAlarmToneOptions();
      final sensorAlertTones =
          await widget.controller.getSensorAlertToneOptions();

      if (!mounted) {
        return;
      }

      setState(() {
        _mainAlarmTones = _ensureSelectedTonePresent(
          tones: mainAlarmTones,
          selectedUri: widget.controller.mainAlarmToneUri,
          selectedTitle: widget.controller.mainAlarmToneTitle,
        );
        _sensorAlertTones = _ensureSelectedTonePresent(
          tones: sensorAlertTones,
          selectedUri: widget.controller.sensorAlarmToneUri,
          selectedTitle: widget.controller.sensorAlarmToneTitle,
        );
        _loadingTones = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingTones = false;
        _toneLoadError = 'Failed to load system tones.';
      });
    }
  }

  List<SystemToneOption> _ensureSelectedTonePresent({
    required List<SystemToneOption> tones,
    required String selectedUri,
    required String selectedTitle,
  }) {
    if (selectedUri.isEmpty) {
      return tones;
    }

    final exists = tones.any((tone) => tone.uri == selectedUri);
    if (exists) {
      return tones;
    }

    return [
      SystemToneOption(
        title: selectedTitle,
        uri: selectedUri,
      ),
      ...tones,
    ];
  }

  Widget _settingsPanel({
    required Widget child,
  }) {
    return Container(
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
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _settingsPanel(
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  title: const Text(
                    'Enable alarm sounds',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Play selected system tones for alerts',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: widget.controller.soundEnabled,
                  onChanged: widget.controller.setSoundEnabled,
                ),
              ),
              const SizedBox(height: 12),
              _settingsPanel(
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  title: const Text(
                    'Enable vibration',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Vibrate on alerts',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: widget.controller.vibrationEnabled,
                  onChanged: widget.controller.setVibrationEnabled,
                ),
              ),
              const SizedBox(height: 12),
              _settingsPanel(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _buildToneSection(),
                ),
              ),
              const SizedBox(height: 12),
              _settingsPanel(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  title: const Text(
                    'Clear all history',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Remove completed oven history',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Clear history?'),
                            content: const Text(
                              'This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true) {
                        await widget.controller.clearHistory();
                      }
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToneSection() {
    if (_loadingTones) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_toneLoadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _toneLoadError!,
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _loadTones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Tones'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SYSTEM TONES',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Main alarm uses Android alarm tones. Sensor alert uses Android notification tones.',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          value: _resolveSelectedValue(
            tones: _mainAlarmTones,
            selectedUri: widget.controller.mainAlarmToneUri,
          ),
          decoration: _dropdownDecoration('Main alarm tone'),
          items: _mainAlarmTones.map((tone) {
            return DropdownMenuItem<String>(
              value: tone.uri,
              child: Text(
                tone.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }

            final selectedTone = _mainAlarmTones.firstWhere(
              (tone) => tone.uri == value,
            );

            await widget.controller.setMainAlarmTone(selectedTone);

            if (!mounted) {
              return;
            }

            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _resolveSelectedValue(
            tones: _sensorAlertTones,
            selectedUri: widget.controller.sensorAlarmToneUri,
          ),
          decoration: _dropdownDecoration('Sensor alert tone'),
          items: _sensorAlertTones.map((tone) {
            return DropdownMenuItem<String>(
              value: tone.uri,
              child: Text(
                tone.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }

            final selectedTone = _sensorAlertTones.firstWhere(
              (tone) => tone.uri == value,
            );

            await widget.controller.setSensorAlarmTone(selectedTone);

            if (!mounted) {
              return;
            }

            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _loadTones,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload Tones'),
          ),
        ),
      ],
    );
  }

  String? _resolveSelectedValue({
    required List<SystemToneOption> tones,
    required String selectedUri,
  }) {
    if (selectedUri.isEmpty) {
      return null;
    }

    final exists = tones.any((tone) => tone.uri == selectedUri);
    return exists ? selectedUri : null;
  }
}