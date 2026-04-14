class SensorStep {
  final String id;
  final int minuteOfDay;
  final String display;
  bool checked;

  SensorStep({
    required this.id,
    required this.minuteOfDay,
    required this.display,
    this.checked = false,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'minuteOfDay': minuteOfDay,
      'display': display,
      'checked': checked,
    };
  }

  factory SensorStep.fromJson(Map<String, dynamic> json) {
    return SensorStep(
      id: json['id'] as String,
      minuteOfDay: json['minuteOfDay'] as int,
      display: json['display'] as String,
      checked: json['checked'] as bool? ?? false,
    );
  }

  SensorStep copyWith({
    String? id,
    int? minuteOfDay,
    String? display,
    bool? checked,
  }) {
    return SensorStep(
      id: id ?? this.id,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      display: display ?? this.display,
      checked: checked ?? this.checked,
    );
  }
}