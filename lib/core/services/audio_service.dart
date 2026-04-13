import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../models/system_tone_option.dart';

enum AlarmSoundType {
  none,
  main,
  sensor,
}

class AudioService {
  AudioService()
      : _player = AudioPlayer(
          playerId: 'laugfs_alarm_player',
        );

  static const MethodChannel _channel =
      MethodChannel('laugfs.smart_tracker/system_tones');

  static const String _fallbackMainAsset =
      'assets/sounds/mixkit-facility-alarm-sound-999.wav';
  static const String _fallbackSensorAsset =
      'assets/sounds/mixkit-emergency-alert-alarm-1007.wav';

  final AudioPlayer _player;

  AlarmSoundType _currentAlarm = AlarmSoundType.none;
  String _currentToneUri = '';

  AlarmSoundType get currentAlarm => _currentAlarm;
  String get currentToneUri => _currentToneUri;

  Future<void> init() async {
    await _configurePlayer();
    await stop();
  }

  Future<void> _configurePlayer() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);

    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  Future<List<SystemToneOption>> getAlarmTones() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('getAlarmTones');

      if (result is! List) {
        return [
          const SystemToneOption(
            title: 'App Main Alarm',
            uri: _fallbackMainAsset,
          ),
        ];
      }

      final tones = result
          .whereType<dynamic>()
          .map((item) {
            final map = Map<dynamic, dynamic>.from(item as Map);
            final title = (map['title'] as String? ?? '').trim();
            final uri = (map['uri'] as String? ?? '').trim();

            if (title.isEmpty || uri.isEmpty) {
              return null;
            }

            return SystemToneOption(
              title: title,
              uri: uri,
            );
          })
          .whereType<SystemToneOption>()
          .toList();

      if (tones.isEmpty) {
        return [
          const SystemToneOption(
            title: 'App Main Alarm',
            uri: _fallbackMainAsset,
          ),
        ];
      }

      final hasFallback = tones.any((tone) => tone.uri == _fallbackMainAsset);
      if (!hasFallback) {
        tones.add(
          const SystemToneOption(
            title: 'App Main Alarm',
            uri: _fallbackMainAsset,
          ),
        );
      }

      return tones;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load alarm tones',
        name: 'AudioService',
        error: e,
        stackTrace: stackTrace,
      );

      return [
        const SystemToneOption(
          title: 'App Main Alarm',
          uri: _fallbackMainAsset,
        ),
      ];
    }
  }

  Future<List<SystemToneOption>> getNotificationTones() async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'getNotificationTones',
      );

      if (result is! List) {
        return [
          const SystemToneOption(
            title: 'App Sensor Alert',
            uri: _fallbackSensorAsset,
          ),
        ];
      }

      final tones = result
          .whereType<dynamic>()
          .map((item) {
            final map = Map<dynamic, dynamic>.from(item as Map);
            final title = (map['title'] as String? ?? '').trim();
            final uri = (map['uri'] as String? ?? '').trim();

            if (title.isEmpty || uri.isEmpty) {
              return null;
            }

            return SystemToneOption(
              title: title,
              uri: uri,
            );
          })
          .whereType<SystemToneOption>()
          .toList();

      if (tones.isEmpty) {
        return [
          const SystemToneOption(
            title: 'App Sensor Alert',
            uri: _fallbackSensorAsset,
          ),
        ];
      }

      final hasFallback = tones.any((tone) => tone.uri == _fallbackSensorAsset);
      if (!hasFallback) {
        tones.add(
          const SystemToneOption(
            title: 'App Sensor Alert',
            uri: _fallbackSensorAsset,
          ),
        );
      }

      return tones;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load notification tones',
        name: 'AudioService',
        error: e,
        stackTrace: stackTrace,
      );

      return [
        const SystemToneOption(
          title: 'App Sensor Alert',
          uri: _fallbackSensorAsset,
        ),
      ];
    }
  }

  Future<SystemToneOption?> getDefaultAlarmTone() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('getDefaultAlarmTone');

      if (result is! Map) {
        return const SystemToneOption(
          title: 'App Main Alarm',
          uri: _fallbackMainAsset,
        );
      }

      final map = Map<dynamic, dynamic>.from(result);
      final title = (map['title'] as String? ?? '').trim();
      final uri = (map['uri'] as String? ?? '').trim();

      if (uri.isEmpty) {
        return const SystemToneOption(
          title: 'App Main Alarm',
          uri: _fallbackMainAsset,
        );
      }

      return SystemToneOption(
        title: title.isEmpty ? 'Default alarm tone' : title,
        uri: uri,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get default alarm tone',
        name: 'AudioService',
        error: e,
        stackTrace: stackTrace,
      );

      return const SystemToneOption(
        title: 'App Main Alarm',
        uri: _fallbackMainAsset,
      );
    }
  }

  Future<SystemToneOption?> getDefaultNotificationTone() async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'getDefaultNotificationTone',
      );

      if (result is! Map) {
        return const SystemToneOption(
          title: 'App Sensor Alert',
          uri: _fallbackSensorAsset,
        );
      }

      final map = Map<dynamic, dynamic>.from(result);
      final title = (map['title'] as String? ?? '').trim();
      final uri = (map['uri'] as String? ?? '').trim();

      if (uri.isEmpty) {
        return const SystemToneOption(
          title: 'App Sensor Alert',
          uri: _fallbackSensorAsset,
        );
      }

      return SystemToneOption(
        title: title.isEmpty ? 'Default notification tone' : title,
        uri: uri,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get default notification tone',
        name: 'AudioService',
        error: e,
        stackTrace: stackTrace,
      );

      return const SystemToneOption(
        title: 'App Sensor Alert',
        uri: _fallbackSensorAsset,
      );
    }
  }

  Future<void> playMainAlarm(String toneUri) async {
    final effectiveTone =
        toneUri.trim().isEmpty ? _fallbackMainAsset : toneUri.trim();

    if (_currentAlarm == AlarmSoundType.main &&
        _currentToneUri == effectiveTone) {
      return;
    }

    await _playAlarm(
      requestedToneUri: effectiveTone,
      fallbackAssetPath: _fallbackMainAsset,
      type: AlarmSoundType.main,
    );
  }

  Future<void> playSensorAlarm(String toneUri) async {
    final effectiveTone =
        toneUri.trim().isEmpty ? _fallbackSensorAsset : toneUri.trim();

    if (_currentAlarm == AlarmSoundType.sensor &&
        _currentToneUri == effectiveTone) {
      return;
    }

    await _playAlarm(
      requestedToneUri: effectiveTone,
      fallbackAssetPath: _fallbackSensorAsset,
      type: AlarmSoundType.sensor,
    );
  }

  Future<void> _playAlarm({
    required String requestedToneUri,
    required String fallbackAssetPath,
    required AlarmSoundType type,
  }) async {
    await _configurePlayer();
    await stop();

    final playedSelected = await _tryPlayRequestedTone(requestedToneUri);
    if (playedSelected) {
      _currentAlarm = type;
      _currentToneUri = requestedToneUri;
      return;
    }

    final playedFallback = await _tryPlayAsset(fallbackAssetPath);
    if (playedFallback) {
      _currentAlarm = type;
      _currentToneUri = fallbackAssetPath;
      return;
    }

    _currentAlarm = AlarmSoundType.none;
    _currentToneUri = '';
  }

  Future<bool> _tryPlayRequestedTone(String toneUri) async {
    final uri = toneUri.trim();
    if (uri.isEmpty) {
      return false;
    }

    if (_looksLikeAndroidSystemTone(uri)) {
      try {
        developer.log(
          'Trying native system tone: $uri',
          name: 'AudioService',
        );

        final result = await _channel.invokeMethod<dynamic>(
          'playTone',
          <String, dynamic>{'uri': uri},
        );

        return result == true;
      } catch (e, stackTrace) {
        developer.log(
          'Native tone playback failed',
          name: 'AudioService',
          error: e,
          stackTrace: stackTrace,
        );
        return false;
      }
    }

    return _tryPlayAsset(uri);
  }

  bool _looksLikeAndroidSystemTone(String uri) {
    return uri.startsWith('content://') ||
        uri.startsWith('file://') ||
        uri.startsWith('android.resource://') ||
        uri.startsWith('settings://');
  }

  Future<bool> _tryPlayAsset(String rawPath) async {
    final candidates = _buildAssetCandidates(rawPath);

    for (final assetPath in candidates) {
      try {
        developer.log(
          'Trying asset playback: $assetPath',
          name: 'AudioService',
        );

        await _player.play(
          AssetSource(assetPath),
          volume: 1.0,
          mode: PlayerMode.mediaPlayer,
        );

        return true;
      } catch (e, stackTrace) {
        developer.log(
          'Asset playback failed for $assetPath',
          name: 'AudioService',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    return false;
  }

  List<String> _buildAssetCandidates(String rawPath) {
    final cleaned = rawPath.trim().replaceAll('\\', '/');
    final Set<String> results = <String>{};

    if (cleaned.isEmpty) {
      return const [];
    }

    if (cleaned.startsWith('assets/')) {
      results.add(cleaned.substring('assets/'.length));
      results.add(cleaned);
    } else {
      results.add(cleaned);
      results.add('assets/$cleaned');
    }

    return results.toList(growable: false);
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<dynamic>('stopTone');
    } catch (_) {}

    try {
      await _player.stop();
    } catch (_) {}

    _currentAlarm = AlarmSoundType.none;
    _currentToneUri = '';
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}