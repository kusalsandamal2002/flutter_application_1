import 'sensor_step.dart';

class OvenItem {
  final String sessionId;
  final String ovenName;
  final int startMinuteOfDay;
  final int endMinuteOfDayRaw;
  final int totalMinutes;
  final String startDisplay;
  final String startRaw;
  final String outDisplay;
  final String outRaw;
  final List<SensorStep> steps;

  OvenItem({
    required this.sessionId,
    required this.ovenName,
    required this.startMinuteOfDay,
    required this.endMinuteOfDayRaw,
    required this.totalMinutes,
    required this.startDisplay,
    required this.startRaw,
    required this.outDisplay,
    required this.outRaw,
    required this.steps,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'ovenName': ovenName,
      'startMinuteOfDay': startMinuteOfDay,
      'endMinuteOfDayRaw': endMinuteOfDayRaw,
      'totalMinutes': totalMinutes,
      'startDisplay': startDisplay,
      'startRaw': startRaw,
      'outDisplay': outDisplay,
      'outRaw': outRaw,
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }

  factory OvenItem.fromJson(Map<String, dynamic> json) {
    return OvenItem(
      sessionId: json['sessionId'] as String,
      ovenName: json['ovenName'] as String,
      startMinuteOfDay: json['startMinuteOfDay'] as int,
      endMinuteOfDayRaw: json['endMinuteOfDayRaw'] as int,
      totalMinutes: json['totalMinutes'] as int,
      startDisplay: json['startDisplay'] as String,
      startRaw: json['startRaw'] as String,
      outDisplay: json['outDisplay'] as String,
      outRaw: json['outRaw'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => SensorStep.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  OvenItem copyWith({
    String? sessionId,
    String? ovenName,
    int? startMinuteOfDay,
    int? endMinuteOfDayRaw,
    int? totalMinutes,
    String? startDisplay,
    String? startRaw,
    String? outDisplay,
    String? outRaw,
    List<SensorStep>? steps,
  }) {
    return OvenItem(
      sessionId: sessionId ?? this.sessionId,
      ovenName: ovenName ?? this.ovenName,
      startMinuteOfDay: startMinuteOfDay ?? this.startMinuteOfDay,
      endMinuteOfDayRaw: endMinuteOfDayRaw ?? this.endMinuteOfDayRaw,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      startDisplay: startDisplay ?? this.startDisplay,
      startRaw: startRaw ?? this.startRaw,
      outDisplay: outDisplay ?? this.outDisplay,
      outRaw: outRaw ?? this.outRaw,
      steps: steps ?? this.steps,
    );
  }
}