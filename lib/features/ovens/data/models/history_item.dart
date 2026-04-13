class HistoryItem {
  final String id;
  final String status;
  final String inTime;
  final String finishTime;
  final String completedAt;

  HistoryItem({
    required this.id,
    required this.status,
    required this.inTime,
    required this.finishTime,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'inTime': inTime,
      'finishTime': finishTime,
      'completedAt': completedAt,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      status: json['status'] as String,
      inTime: json['inTime'] as String,
      finishTime: json['finishTime'] as String,
      completedAt: json['completedAt'] as String? ?? '',
    );
  }
}