import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../controllers/oven_controller.dart';
import 'manage_ovens_page.dart';
import 'system_tones_page.dart';

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

  Future<void> _openSystemTonesPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SystemTonesPage(controller: widget.controller),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openManageOvensPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageOvensPage(controller: widget.controller),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _confirmClearHistory() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear history?'),
          content: const Text(
            'This action cannot be undone. All completed oven history will be removed.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.controller.clearHistory();
    await _showAppMessage('History cleared.');
  }

  String _toneSummary() {
    final String main = widget.controller.mainAlarmToneTitle.trim().isEmpty
        ? 'Default'
        : widget.controller.mainAlarmToneTitle.trim();
    final String sensor = widget.controller.sensorAlarmToneTitle.trim().isEmpty
        ? 'Default'
        : widget.controller.sensorAlarmToneTitle.trim();

    return 'Main: $main • Sensor: $sensor';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final int ovenCount = widget.controller.managedOvens.length;
        final int activeCount = widget.controller.ovens.length;
        final int availableCount = ovenCount - activeCount < 0
            ? 0
            : ovenCount - activeCount;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                _SettingsTopBar(
                  title: 'Settings',
                  subtitle: 'Customize alerts, tones, and oven setup',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 18),
                _HeroSettingsCard(
                  soundEnabled: widget.controller.soundEnabled,
                  vibrationEnabled: widget.controller.vibrationEnabled,
                  ovenCount: ovenCount,
                  activeCount: activeCount,
                  availableCount: availableCount,
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Preferences',
                  subtitle: 'Core alert behavior for your oven tracking app',
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Column(
                    children: <Widget>[
                      _PremiumSwitchTile(
                        icon: Icons.volume_up_rounded,
                        iconColor: AppColors.primary,
                        title: 'Enable alarm sounds',
                        subtitle: 'Play selected tones for due alerts and oven completion',
                        value: widget.controller.soundEnabled,
                        onChanged: widget.controller.setSoundEnabled,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _PremiumSwitchTile(
                        icon: Icons.vibration_rounded,
                        iconColor: AppColors.warning,
                        title: 'Enable vibration',
                        subtitle: 'Vibrate when alerts are triggered',
                        value: widget.controller.vibrationEnabled,
                        onChanged: widget.controller.setVibrationEnabled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Configuration',
                  subtitle: 'Open detailed pages to fine-tune tones and oven list',
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Column(
                    children: <Widget>[
                      _PremiumNavigationTile(
                        icon: Icons.music_note_rounded,
                        iconColor: AppColors.primary,
                        title: 'System Tones',
                        subtitle: _toneSummary(),
                        onTap: _openSystemTonesPage,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _PremiumNavigationTile(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.warning,
                        title: 'Manage Ovens',
                        subtitle:
                            '$ovenCount configured • $activeCount active • $availableCount available',
                        onTap: _openManageOvensPage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Danger Zone',
                  subtitle: 'Actions here permanently remove saved information',
                ),
                const SizedBox(height: 12),
                _DangerCard(
                  title: 'Clear all history',
                  subtitle: 'Remove all completed oven history records',
                  buttonLabel: 'Clear',
                  onPressed: _confirmClearHistory,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsTopBar extends StatelessWidget {
  const _SettingsTopBar({
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

class _HeroSettingsCard extends StatelessWidget {
  const _HeroSettingsCard({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.ovenCount,
    required this.activeCount,
    required this.availableCount,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final int ovenCount;
  final int activeCount;
  final int availableCount;

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
            'CONTROL CENTER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Keep alerts sharp and oven setup organized.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoChip(
                icon: soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: soundEnabled ? 'Sound On' : 'Sound Off',
                color: soundEnabled ? AppColors.primary : AppColors.textMuted,
              ),
              _InfoChip(
                icon: vibrationEnabled
                    ? Icons.vibration_rounded
                    : Icons.do_not_disturb_alt_rounded,
                label: vibrationEnabled ? 'Vibration On' : 'Vibration Off',
                color: vibrationEnabled ? AppColors.warning : AppColors.textMuted,
              ),
              _InfoChip(
                icon: Icons.local_fire_department_rounded,
                label: '$ovenCount Ovens',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _MiniStatCard(
                title: 'Active',
                value: '$activeCount',
                icon: Icons.local_fire_department_rounded,
              ),
              const SizedBox(width: 12),
              _MiniStatCard(
                title: 'Available',
                value: '$availableCount',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
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
            letterSpacing: 0.2,
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
    );
  }
}

class _PremiumSwitchTile extends StatelessWidget {
  const _PremiumSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      secondary: Container(
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
        child: Text(
          subtitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _PremiumNavigationTile extends StatelessWidget {
  const _PremiumNavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
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
        child: Text(
          subtitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
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

class _DangerCard extends StatelessWidget {
  const _DangerCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.card,
            AppColors.danger.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.28),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
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
          FilledButton.tonal(
            onPressed: onPressed,
            child: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
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
}