import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/system_tone_option.dart';
import '../controllers/oven_controller.dart';

class SystemTonesPage extends StatefulWidget {
  const SystemTonesPage({
    super.key,
    required this.controller,
  });

  final OvenController controller;

  @override
  State<SystemTonesPage> createState() => _SystemTonesPageState();
}

class _SystemTonesPageState extends State<SystemTonesPage> {
  bool _loading = true;
  bool _reloading = false;
  String? _error;

  List<SystemToneOption> _mainTones = <SystemToneOption>[];
  List<SystemToneOption> _sensorTones = <SystemToneOption>[];

  @override
  void initState() {
    super.initState();
    _loadTones();
  }

  Future<void> _showAppMessage(
    String message, {
    bool isError = false,
  }) async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  List<SystemToneOption> _uniqueToneList(List<SystemToneOption> tones) {
    final Map<String, SystemToneOption> unique = <String, SystemToneOption>{};

    for (final SystemToneOption tone in tones) {
      final String key = tone.uri.trim();
      if (key.isEmpty) {
        continue;
      }

      unique.putIfAbsent(key, () => tone);
    }

    return unique.values.toList();
  }

  List<SystemToneOption> _ensureSelectedTonePresent({
    required List<SystemToneOption> tones,
    required String selectedUri,
    required String selectedTitle,
  }) {
    final List<SystemToneOption> unique = _uniqueToneList(tones);

    if (selectedUri.trim().isEmpty) {
      return unique;
    }

    final bool exists = unique.any((tone) => tone.uri == selectedUri.trim());
    if (exists) {
      return unique;
    }

    return <SystemToneOption>[
      SystemToneOption(
        title: selectedTitle.trim().isEmpty ? 'Current tone' : selectedTitle,
        uri: selectedUri.trim(),
      ),
      ...unique,
    ];
  }

  Future<void> _loadTones({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _reloading = true;
        _error = null;
      });
    }

    try {
      await widget.controller.init();

      final List<SystemToneOption> main = await widget.controller
          .getMainAlarmToneOptions();
      final List<SystemToneOption> sensor = await widget.controller
          .getSensorAlertToneOptions();

      if (!mounted) {
        return;
      }

      setState(() {
        _mainTones = _ensureSelectedTonePresent(
          tones: main,
          selectedUri: widget.controller.mainAlarmToneUri,
          selectedTitle: widget.controller.mainAlarmToneTitle,
        );
        _sensorTones = _ensureSelectedTonePresent(
          tones: sensor,
          selectedUri: widget.controller.sensorAlarmToneUri,
          selectedTitle: widget.controller.sensorAlarmToneTitle,
        );
        _loading = false;
        _reloading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _reloading = false;
        _error = 'Failed to load system tones.';
      });
    }
  }

  Future<void> _openTonePicker({
    required String title,
    required String subtitle,
    required List<SystemToneOption> tones,
    required String currentValue,
    required Future<void> Function(SystemToneOption tone) onSelected,
  }) async {
    if (tones.isEmpty) {
      await _showAppMessage(
        'No tones available on this device.',
        isError: true,
      );
      return;
    }

    final SystemToneOption? selectedTone = await showModalBottomSheet<SystemToneOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _TonePickerSheet(
          title: title,
          subtitle: subtitle,
          tones: tones,
          selectedUri: currentValue,
        );
      },
    );

    if (selectedTone == null) {
      return;
    }

    await onSelected(selectedTone);

    if (!mounted) {
      return;
    }

    setState(() {});

    await _showAppMessage('"${selectedTone.title}" selected.');
  }

  @override
  Widget build(BuildContext context) {
    final String mainTitle =
        widget.controller.mainAlarmToneTitle.trim().isEmpty
            ? 'Not selected'
            : widget.controller.mainAlarmToneTitle.trim();

    final String sensorTitle =
        widget.controller.sensorAlarmToneTitle.trim().isEmpty
            ? 'Not selected'
            : widget.controller.sensorAlarmToneTitle.trim();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: <Widget>[
                  _PageHeader(
                    title: 'System Tones',
                    subtitle: 'Choose alert sounds for main alarms and sensor reminders',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 18),
                  _HeroToneCard(
                    mainToneTitle: mainTitle,
                    sensorToneTitle: sensorTitle,
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...<Widget>[
                    _InlineErrorCard(
                      message: _error!,
                      onRetry: () => _loadTones(showLoader: true),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _SectionTitle(
                    title: 'Tone Settings',
                    subtitle: 'Tap a card to open a premium tone selector',
                  ),
                  const SizedBox(height: 12),
                  _SettingsSurfaceCard(
                    child: Column(
                      children: <Widget>[
                        _ToneOptionTile(
                          icon: Icons.notifications_active_rounded,
                          iconColor: AppColors.primary,
                          title: 'Main Alarm Tone',
                          subtitle:
                              'Used when an oven session finishes and needs immediate attention',
                          value: mainTitle,
                          onTap: () {
                            _openTonePicker(
                              title: 'Main Alarm Tone',
                              subtitle: 'Select the sound for oven completion alerts',
                              tones: _mainTones,
                              currentValue: widget.controller.mainAlarmToneUri,
                              onSelected: widget.controller.setMainAlarmTone,
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _ToneOptionTile(
                          icon: Icons.sensors_rounded,
                          iconColor: AppColors.warning,
                          title: 'Sensor Alert Tone',
                          subtitle:
                              'Used for step-by-step sensor check reminders during tracking',
                          value: sensorTitle,
                          onTap: () {
                            _openTonePicker(
                              title: 'Sensor Alert Tone',
                              subtitle: 'Select the sound for sensor reminder alerts',
                              tones: _sensorTones,
                              currentValue: widget.controller.sensorAlarmToneUri,
                              onSelected: widget.controller.setSensorAlarmTone,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsSurfaceCard(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Reload System Tones',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Refresh the available tones from the device',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonal(
                            onPressed: _reloading
                                ? null
                                : () => _loadTones(showLoader: false),
                            child: _reloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Reload',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroToneCard extends StatelessWidget {
  const _HeroToneCard({
    required this.mainToneTitle,
    required this.sensorToneTitle,
  });

  final String mainToneTitle;
  final String sensorToneTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF12284B),
            Color(0xFF101F39),
            Color(0xFF0B1628),
          ],
        ),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.95),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'ACTIVE SELECTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose tones that are clear and easy to recognize.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _TonePreviewRow(
            label: 'Main Alarm',
            value: mainToneTitle,
            color: AppColors.primary,
            icon: Icons.notifications_active_rounded,
          ),
          const SizedBox(height: 12),
          _TonePreviewRow(
            label: 'Sensor Alert',
            value: sensorToneTitle,
            color: AppColors.warning,
            icon: Icons.sensors_rounded,
          ),
        ],
      ),
    );
  }
}

class _TonePreviewRow extends StatelessWidget {
  const _TonePreviewRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSurfaceCard extends StatelessWidget {
  const _SettingsSurfaceCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.card,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ToneOptionTile extends StatelessWidget {
  const _ToneOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              subtitle,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
      trailing: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TonePickerSheet extends StatelessWidget {
  const _TonePickerSheet({
    required this.title,
    required this.subtitle,
    required this.tones,
    required this.selectedUri,
  });

  final String title;
  final String subtitle;
  final List<SystemToneOption> tones;
  final String selectedUri;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: AppColors.surfaceAlt.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: tones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final SystemToneOption tone = tones[index];
                  final bool isSelected = tone.uri == selectedUri;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).pop(tone),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.45)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.16)
                                    : AppColors.surfaceAlt.withValues(alpha: 0.48),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.music_note_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tone.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}