import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/models/system_tone_option.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/utils/id_utils.dart';
import '../../../../core/utils/time_utils.dart';
import '../../data/models/history_item.dart';
import '../../data/models/oven_item.dart';
import '../../data/models/sensor_step.dart';

class OvenController extends ChangeNotifier {
  OvenController({
    required AudioService audioService,
    required VibrationService vibrationService,
    required StorageService storageService,
    required NotificationService notificationService,
  })  : _audioService = audioService,
        _vibrationService = vibrationService,
        _storageService = storageService,
        _notificationService = notificationService;

  static const String _defaultMainAlarmToneUri =
      'assets/sounds/mixkit-facility-alarm-sound-999.wav';
  static const String _defaultMainAlarmToneTitle = 'App Main Alarm';
  static const String _defaultSensorAlarmToneUri =
      'assets/sounds/mixkit-emergency-alert-alarm-1007.wav';
  static const String _defaultSensorAlarmToneTitle = 'App Sensor Alert';

  final AudioService _audioService;
  final VibrationService _vibrationService;
  final StorageService _storageService;
  final NotificationService _notificationService;

  final List<OvenItem> ovens = [];
  final List<HistoryItem> history = [];

  final Set<String> _triggeredMainAlerts = <String>{};
  final Set<String> _triggeredSensorAlerts = <String>{};

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  String mainAlarmToneUri = '';
  String mainAlarmToneTitle = 'Default alarm tone';

  String sensorAlarmToneUri = '';
  String sensorAlarmToneTitle = 'Default notification tone';

  bool _initialized = false;
  bool _tickInProgress = false;

  DateTime get now => _now;

  String get liveClock => TimeUtils.format12Hour(
        _now.hour,
        _now.minute,
        withSeconds: true,
        second: _now.second,
      );

  int get nowMinuteOfDay => _now.hour * 60 + _now.minute;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      await _audioService.init();
      await _notificationService.init();
      await loadState();
      await _ensureDefaultTonesLoaded();
      _now = DateTime.now();
      startClock();
      await _runTick();
    } catch (e, stackTrace) {
      _initialized = false;
      developer.log(
        'Failed to initialize OvenController',
        name: 'OvenController',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _runTick();
    });
  }

  void stopClock() {
    _clockTimer?.cancel();
  }

  Future<void> disposeServices() async {
    _clockTimer?.cancel();
    await _audioService.dispose();
  }

  Future<void> _runTick() async {
    if (_tickInProgress) {
      return;
    }

    _tickInProgress = true;

    try {
      _now = DateTime.now();
      notifyListeners();

      await _safeHandleAlerts();
      await _safeSyncAlarmPlayback();
    } finally {
      _tickInProgress = false;
    }
  }

  Future<void> _safeHandleAlerts() async {
    try {
      await _handleAlerts();
    } catch (e, stackTrace) {
      developer.log(
        'handleAlerts failed',
        name: 'OvenController',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _safeSyncAlarmPlayback() async {
    try {
      await _syncAlarmPlayback();
    } catch (e, stackTrace) {
      developer.log(
        'syncAlarmPlayback failed',
        name: 'OvenController',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  String? validateDuration({
    required int hours,
    required int minutes,
  }) {
    if (hours < 0 || minutes < 0) {
      return 'Duration cannot be negative.';
    }
    if (hours == 0 && minutes == 0) {
      return 'Enter a valid duration.';
    }
    if (minutes > 59) {
      return 'Minutes should be between 0 and 59.';
    }
    if (hours > 23) {
      return 'Hours should be 23 or less.';
    }
    return null;
  }

  bool isOvenActive(String ovenName) {
    return ovens.any((oven) => oven.ovenName == ovenName);
  }

  Future<List<SystemToneOption>> getMainAlarmToneOptions() async {
    final tones = await _audioService.getAlarmTones();

    if (tones.isEmpty && mainAlarmToneUri.isNotEmpty) {
      return [
        SystemToneOption(
          title: mainAlarmToneTitle,
          uri: mainAlarmToneUri,
        ),
      ];
    }

    return tones;
  }

  Future<List<SystemToneOption>> getSensorAlertToneOptions() async {
    final tones = await _audioService.getNotificationTones();

    if (tones.isEmpty && sensorAlarmToneUri.isNotEmpty) {
      return [
        SystemToneOption(
          title: sensorAlarmToneTitle,
          uri: sensorAlarmToneUri,
        ),
      ];
    }

    return tones;
  }

  Future<void> setMainAlarmTone(SystemToneOption tone) async {
    mainAlarmToneUri = tone.uri.trim();
    mainAlarmToneTitle = tone.title;
    await _persistSettings();
    notifyListeners();
    await _safeSyncAlarmPlayback();
  }

  Future<void> setSensorAlarmTone(SystemToneOption tone) async {
    sensorAlarmToneUri = tone.uri.trim();
    sensorAlarmToneTitle = tone.title;
    await _persistSettings();
    notifyListeners();
    await _safeSyncAlarmPlayback();
  }

  int _mainNotificationId(String sessionId) {
    return sessionId.hashCode & 0x7fffffff;
  }

  int _sensorNotificationId(String stepId) {
    return stepId.hashCode & 0x7fffffff;
  }

  Future<void> addOvenTracking({
    required String ovenName,
    required TimeOfDay startTime,
    required int addHours,
    required int addMinutes,
  }) async {
    final validation = validateDuration(hours: addHours, minutes: addMinutes);

    if (validation != null) {
      throw Exception(validation);
    }

    if (isOvenActive(ovenName)) {
      throw Exception('$ovenName is already active.');
    }

    final startMinuteOfDay = TimeUtils.minuteOfDayFromTimeOfDay(startTime);
    final totalMinutes = addHours * 60 + addMinutes;
    final endMinuteRaw = (startMinuteOfDay + totalMinutes) % (24 * 60);
    final outTime = TimeUtils.addDurationToTime(startTime, addHours, addMinutes);
    final sessionId = IdUtils.sessionId(ovenName);

    final steps = _buildSensorSteps(
      ovenName: ovenName,
      sessionId: sessionId,
      startMinuteOfDay: startMinuteOfDay,
      totalMinutes: totalMinutes,
    );

    ovens.add(
      OvenItem(
        sessionId: sessionId,
        ovenName: ovenName,
        startMinuteOfDay: startMinuteOfDay,
        endMinuteOfDayRaw: endMinuteRaw,
        totalMinutes: totalMinutes,
        startDisplay: TimeUtils.formatTimeOfDay(startTime),
        startRaw: TimeUtils.formatTimeOfDay(startTime),
        outDisplay: TimeUtils.formatTimeOfDay(outTime),
        outRaw: TimeUtils.formatTimeOfDay(outTime),
        steps: steps,
      ),
    );

    await _persistAll();
    notifyListeners();

    await _safeHandleAlerts();
    await _safeSyncAlarmPlayback();
  }

  List<SensorStep> _buildSensorSteps({
    required String ovenName,
    required String sessionId,
    required int startMinuteOfDay,
    required int totalMinutes,
  }) {
    final List<SensorStep> result = [];
    const sensorGap = 30;

    for (int passed = sensorGap; passed < totalMinutes; passed += sensorGap) {
      final minute = (startMinuteOfDay + passed) % (24 * 60);
      final hour = minute ~/ 60;
      final min = minute % 60;

      result.add(
        SensorStep(
          id: '${sessionId}_${IdUtils.stepId(ovenName, minute)}',
          minuteOfDay: minute,
          display: TimeUtils.format12Hour(hour, min),
        ),
      );
    }

    return result;
  }

  Future<void> markSensorChecked({
    required String sessionId,
    required String stepId,
  }) async {
    final ovenIndex = ovens.indexWhere((o) => o.sessionId == sessionId);
    if (ovenIndex == -1) {
      return;
    }

    final oven = ovens[ovenIndex];
    final updatedSteps = oven.steps.map((step) {
      if (step.id == stepId) {
        return step.copyWith(checked: true);
      }
      return step;
    }).toList();

    ovens[ovenIndex] = oven.copyWith(steps: updatedSteps);

    _triggeredSensorAlerts.remove('${oven.sessionId}_$stepId');

    await _notificationService.cancel(_sensorNotificationId(stepId));
    await _persistAll();
    notifyListeners();
    await _safeSyncAlarmPlayback();
  }

  Future<void> closeOven(String sessionId) async {
    final ovenIndex = ovens.indexWhere((o) => o.sessionId == sessionId);
    if (ovenIndex == -1) {
      return;
    }

    final oven = ovens.removeAt(ovenIndex);

    history.insert(
      0,
      HistoryItem(
        id: oven.ovenName,
        status: 'Completed',
        inTime: oven.startDisplay,
        finishTime: oven.outDisplay,
        completedAt: DateTime.now().toIso8601String(),
      ),
    );

    _triggeredMainAlerts.remove(sessionId);

    await _notificationService.cancel(_mainNotificationId(oven.sessionId));

    for (final step in oven.steps) {
      _triggeredSensorAlerts.remove('${oven.sessionId}_${step.id}');
      await _notificationService.cancel(_sensorNotificationId(step.id));
    }

    await _persistAll();
    notifyListeners();
    await _safeSyncAlarmPlayback();
  }

  Future<void> clearHistory() async {
    history.clear();
    await _persistAll();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    await _persistSettings();

    if (!soundEnabled) {
      await _audioService.stop();
    } else {
      await _safeHandleAlerts();
      await _safeSyncAlarmPlayback();
    }

    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    await _persistSettings();
    notifyListeners();
  }

  bool _isTimeDue({
    required int startMinute,
    required int targetMinute,
    required int nowMinute,
  }) {
    if (startMinute <= targetMinute) {
      return nowMinute >= targetMinute;
    }

    final wrappedNow =
        nowMinute < startMinute ? nowMinute + (24 * 60) : nowMinute;
    final wrappedTarget = targetMinute + (24 * 60);

    return wrappedNow >= wrappedTarget;
  }

  bool _isMainAlertPending(OvenItem oven) {
    return _isTimeDue(
      startMinute: oven.startMinuteOfDay,
      targetMinute: oven.endMinuteOfDayRaw,
      nowMinute: nowMinuteOfDay,
    );
  }

  bool _isSensorAlertPending(OvenItem oven, SensorStep step) {
    return !step.checked &&
        _isTimeDue(
          startMinute: oven.startMinuteOfDay,
          targetMinute: step.minuteOfDay,
          nowMinute: nowMinuteOfDay,
        );
  }

  bool isOvenCompleted(OvenItem oven) {
    return _isMainAlertPending(oven);
  }

  bool isSensorCheckDue(OvenItem oven, SensorStep step) {
    return _isSensorAlertPending(oven, step);
  }

  int dueSensorCheckCountForOven(OvenItem oven) {
    return oven.steps.where((step) => _isSensorAlertPending(oven, step)).length;
  }

  int dueChecksCount() {
    int count = 0;
    for (final oven in ovens) {
      for (final step in oven.steps) {
        if (_isSensorAlertPending(oven, step)) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> _syncAlarmPlayback() async {
    if (!soundEnabled) {
      await _audioService.stop();
      return;
    }

    bool hasPendingMainAlert = false;
    bool hasPendingSensorAlert = false;

    for (final oven in ovens) {
      if (_isMainAlertPending(oven)) {
        hasPendingMainAlert = true;
        break;
      }
    }

    if (!hasPendingMainAlert) {
      for (final oven in ovens) {
        for (final step in oven.steps) {
          if (_isSensorAlertPending(oven, step)) {
            hasPendingSensorAlert = true;
            break;
          }
        }
        if (hasPendingSensorAlert) {
          break;
        }
      }
    }

    if (hasPendingMainAlert) {
      await _audioService.playMainAlarm(mainAlarmToneUri);
      return;
    }

    if (hasPendingSensorAlert) {
      await _audioService.playSensorAlarm(sensorAlarmToneUri);
      return;
    }

    await _audioService.stop();
  }

  Future<void> _handleAlerts() async {
    for (final oven in ovens) {
      final mainIsDue = _isMainAlertPending(oven);

      if (mainIsDue && !_triggeredMainAlerts.contains(oven.sessionId)) {
        _triggeredMainAlerts.add(oven.sessionId);

        if (vibrationEnabled) {
          await _vibrationService.vibrateBrief();
        }

        await _notificationService.showMainAlert(
          id: _mainNotificationId(oven.sessionId),
          ovenName: oven.ovenName,
          finishTime: oven.outDisplay,
        );
      }

      for (final step in oven.steps) {
        final sensorKey = '${oven.sessionId}_${step.id}';
        final stepIsDue = _isSensorAlertPending(oven, step);

        if (stepIsDue && !_triggeredSensorAlerts.contains(sensorKey)) {
          _triggeredSensorAlerts.add(sensorKey);

          if (vibrationEnabled) {
            await _vibrationService.vibrateBrief();
          }

          await _notificationService.showSensorAlert(
            id: _sensorNotificationId(step.id),
            ovenName: oven.ovenName,
            sensorTime: step.display,
          );
        }
      }
    }
  }

  Future<void> _ensureDefaultTonesLoaded() async {
    bool changed = false;

    if (mainAlarmToneUri.trim().isEmpty) {
      final defaultAlarmTone = await _audioService.getDefaultAlarmTone();

      if (defaultAlarmTone != null && defaultAlarmTone.uri.trim().isNotEmpty) {
        mainAlarmToneUri = defaultAlarmTone.uri.trim();
        mainAlarmToneTitle = defaultAlarmTone.title;
      } else {
        mainAlarmToneUri = _defaultMainAlarmToneUri;
        mainAlarmToneTitle = _defaultMainAlarmToneTitle;
      }

      changed = true;
    }

    if (sensorAlarmToneUri.trim().isEmpty) {
      final defaultNotificationTone =
          await _audioService.getDefaultNotificationTone();

      if (defaultNotificationTone != null &&
          defaultNotificationTone.uri.trim().isNotEmpty) {
        sensorAlarmToneUri = defaultNotificationTone.uri.trim();
        sensorAlarmToneTitle = defaultNotificationTone.title;
      } else {
        sensorAlarmToneUri = _defaultSensorAlarmToneUri;
        sensorAlarmToneTitle = _defaultSensorAlarmToneTitle;
      }

      changed = true;
    }

    if (changed) {
      await _persistSettings();
      notifyListeners();
    }
  }

  Future<void> loadState() async {
    final ovensJson = await _storageService.readString(StorageKeys.ovens);
    final historyJson = await _storageService.readString(StorageKeys.history);
    final settingsJson = await _storageService.readString('settings_json');

    ovens.clear();
    history.clear();
    _triggeredMainAlerts.clear();
    _triggeredSensorAlerts.clear();

    if (ovensJson != null && ovensJson.isNotEmpty) {
      final decoded = jsonDecode(ovensJson) as List<dynamic>;
      ovens.addAll(
        decoded.map(
          (e) => OvenItem.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
    }

    if (historyJson != null && historyJson.isNotEmpty) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      history.addAll(
        decoded.map(
          (e) => HistoryItem.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
    }

    if (settingsJson != null && settingsJson.isNotEmpty) {
      final decoded = jsonDecode(settingsJson) as Map<String, dynamic>;
      soundEnabled = decoded['soundEnabled'] as bool? ?? true;
      vibrationEnabled = decoded['vibrationEnabled'] as bool? ?? true;
      mainAlarmToneUri = (decoded['mainAlarmToneUri'] as String? ?? '').trim();
      mainAlarmToneTitle =
          decoded['mainAlarmToneTitle'] as String? ?? 'Default alarm tone';
      sensorAlarmToneUri =
          (decoded['sensorAlarmToneUri'] as String? ?? '').trim();
      sensorAlarmToneTitle = decoded['sensorAlarmToneTitle'] as String? ??
          'Default notification tone';
    }

    notifyListeners();
  }

  Future<void> _persistAll() async {
    await _storageService.saveString(
      StorageKeys.ovens,
      jsonEncode(ovens.map((e) => e.toJson()).toList()),
    );

    await _storageService.saveString(
      StorageKeys.history,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );

    await _persistSettings();
  }

  Future<void> _persistSettings() async {
    await _storageService.saveString(
      'settings_json',
      jsonEncode({
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'mainAlarmToneUri': mainAlarmToneUri,
        'mainAlarmToneTitle': mainAlarmToneTitle,
        'sensorAlarmToneUri': sensorAlarmToneUri,
        'sensorAlarmToneTitle': sensorAlarmToneTitle,
      }),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}