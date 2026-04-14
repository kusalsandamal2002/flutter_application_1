import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_defaults.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/vibration_service.dart';
import '../controllers/oven_controller.dart';
import 'active_ovens_page.dart';
import 'due_checks_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'start_tracking_page.dart';

class OvenTrackerHomePage extends StatefulWidget {
  const OvenTrackerHomePage({super.key});

  @override
  State<OvenTrackerHomePage> createState() => _OvenTrackerHomePageState();
}

class _OvenTrackerHomePageState extends State<OvenTrackerHomePage>
    with WidgetsBindingObserver {
  late final OvenController controller;

  final TextEditingController hourController = TextEditingController(text: '0');
  final TextEditingController minuteController =
      TextEditingController(text: '45');

  String selectedOven = AppDefaults.defaultOven;
  TimeOfDay selectedTime = TimeOfDay.now();
  bool startTimeManuallyPicked = false;

  int currentIndex = 0;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller = OvenController(
      audioService: AudioService(),
      vibrationService: VibrationService(),
      storageService: StorageService(),
      notificationService: NotificationService(),
    );

    controller.addListener(_handleControllerTick);

    final now = DateTime.now();
    selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);

    _initializeController();
  }

  List<String> _managedOvenOptions() {
    if (controller.managedOvens.isNotEmpty) {
      return controller.managedOvens;
    }
    return AppDefaults.ovenOptions;
  }

  List<String> _availableOvens() {
    final activeOvenNames = controller.ovens.map((e) => e.ovenName).toSet();
    return _managedOvenOptions()
        .where((oven) => !activeOvenNames.contains(oven))
        .toList();
  }

  String _fallbackSelectedOven() {
    final managed = _managedOvenOptions();
    if (managed.isNotEmpty) {
      return managed.first;
    }
    return AppDefaults.defaultOven;
  }

  Future<void> _initializeController() async {
    try {
      await controller.init();

      if (!mounted) {
        return;
      }

      final availableOvens = _availableOvens();

      setState(() {
        _isInitializing = false;
        _initError = null;
        selectedOven = availableOvens.contains(selectedOven)
            ? selectedOven
            : (availableOvens.isNotEmpty
                ? availableOvens.first
                : _fallbackSelectedOven());
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _initError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_handleControllerTick);
    hourController.dispose();
    minuteController.dispose();
    controller.disposeServices();
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.startClock();
    }
  }

  void _handleControllerTick() {
    if (!mounted || _isInitializing) {
      return;
    }

    if (!startTimeManuallyPicked) {
      final now = controller.now;
      final updatedTime = TimeOfDay(hour: now.hour, minute: now.minute);

      if (updatedTime.hour != selectedTime.hour ||
          updatedTime.minute != selectedTime.minute) {
        setState(() {
          selectedTime = updatedTime;
        });
      }
    }

    final availableOvens = _availableOvens();

    final nextSelectedOven = availableOvens.contains(selectedOven)
        ? selectedOven
        : (availableOvens.isNotEmpty
            ? availableOvens.first
            : _fallbackSelectedOven());

    if (nextSelectedOven != selectedOven) {
      setState(() {
        selectedOven = nextSelectedOven;
      });
    }
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
        startTimeManuallyPicked = true;
      });
    }
  }

  Future<void> startTracking() async {
    final availableOvens = _availableOvens();

    if (availableOvens.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ovens available right now.'),
        ),
      );
      return;
    }

    final trackingOven = availableOvens.contains(selectedOven)
        ? selectedOven
        : availableOvens.first;

    final hours = int.tryParse(hourController.text.trim()) ?? 0;
    final minutes = int.tryParse(minuteController.text.trim()) ?? 0;

    final trackingTime = startTimeManuallyPicked
        ? selectedTime
        : TimeOfDay(hour: controller.now.hour, minute: controller.now.minute);

    try {
      await controller.addOvenTracking(
        ovenName: trackingOven,
        startTime: trackingTime,
        addHours: hours,
        addMinutes: minutes,
      );

      if (!mounted) {
        return;
      }

      final updatedAvailableOvens = _availableOvens();

      setState(() {
        final now = controller.now;
        selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
        startTimeManuallyPicked = false;
        selectedOven = updatedAvailableOvens.isNotEmpty
            ? updatedAvailableOvens.first
            : _fallbackSelectedOven();
        currentIndex = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracking started successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(controller: controller),
      ),
    );
  }

  Future<void> openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(controller: controller),
      ),
    );

    if (!mounted) {
      return;
    }

    final availableOvens = _availableOvens();

    setState(() {
      selectedOven = availableOvens.contains(selectedOven)
          ? selectedOven
          : (availableOvens.isNotEmpty
              ? availableOvens.first
              : _fallbackSelectedOven());
    });
  }

  Future<void> confirmCloseOven(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Close oven?'),
          content: const Text('This will move the oven session to history.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.closeOven(sessionId);

      if (!mounted) {
        return;
      }

      final availableOvens = _availableOvens();

      setState(() {
        selectedOven = availableOvens.isNotEmpty
            ? availableOvens.first
            : _fallbackSelectedOven();
      });
    }
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

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 42,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load tracking page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isInitializing = true;
                      _initError = null;
                    });
                    _initializeController();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final availableOvens = _availableOvens();

    final safeSelectedOven = availableOvens.contains(selectedOven)
        ? selectedOven
        : (availableOvens.isNotEmpty
            ? availableOvens.first
            : _fallbackSelectedOven());

    switch (currentIndex) {
      case 0:
        return StartTrackingPage(
          controller: controller,
          selectedOven: safeSelectedOven,
          selectedTime: selectedTime,
          hourController: hourController,
          minuteController: minuteController,
          startTimeManuallyPicked: startTimeManuallyPicked,
          onOvenChanged: (value) {
            setState(() {
              selectedOven = value;
            });
          },
          onPickStartTime: pickStartTime,
          onStartTracking: startTracking,
          ovenOptions: controller.managedOvens,
        );
      case 1:
        return ActiveOvensPage(
          controller: controller,
          onCloseOven: confirmCloseOven,
          onCheckStep: ({
            required String sessionId,
            required String stepId,
          }) {
            controller.markSensorChecked(
              sessionId: sessionId,
              stepId: stepId,
            );
          },
        );
      case 2:
        return DueChecksPage(
          controller: controller,
          onCheckStep: ({
            required String sessionId,
            required String stepId,
          }) {
            controller.markSensorChecked(
              sessionId: sessionId,
              stepId: stepId,
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Start Tracking',
      'Active Ovens',
      'Due Checks',
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final dueCount = _dueChecksCount();

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(
              titles[currentIndex],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: openHistory,
                icon: const Icon(Icons.history_rounded),
                tooltip: 'History',
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Settings',
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bg,
                  AppColors.surface,
                ],
              ),
            ),
            child: _buildBody(),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  height: 76,
                  backgroundColor: Colors.transparent,
                  indicatorColor: AppColors.primarySoft,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.add_circle_outline_rounded),
                      selectedIcon: Icon(Icons.add_circle_rounded),
                      label: 'Start',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: controller.ovens.isNotEmpty,
                        label: Text('${controller.ovens.length}'),
                        child: const Icon(
                          Icons.local_fire_department_outlined,
                        ),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: controller.ovens.isNotEmpty,
                        label: Text('${controller.ovens.length}'),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                        ),
                      ),
                      label: 'Active',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: dueCount > 0,
                        label: Text('$dueCount'),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                        ),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: dueCount > 0,
                        label: Text('$dueCount'),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                        ),
                      ),
                      label: 'Due',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}