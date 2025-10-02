class Schedule {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final int toleranceMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Schedule({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.toleranceMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      name: json['name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      toleranceMinutes: json['tolerance_minutes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'tolerance_minutes': toleranceMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
