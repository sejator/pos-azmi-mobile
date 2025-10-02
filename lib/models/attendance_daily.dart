class AttendanceDaily {
  final int id;
  final int employeeId;
  final String attendanceDate;
  final String scheduleIn;
  final String scheduleOut;
  final String? clockIn;
  final String? clockOut;
  final String? clockInLat;
  final String? clockInLng;
  final String? clockOutLat;
  final String? clockOutLng;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceDaily({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    required this.scheduleIn,
    required this.scheduleOut,
    this.clockIn,
    this.clockOut,
    this.clockInLat,
    this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
    required this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceDaily.fromJson(Map<String, dynamic> json) {
    return AttendanceDaily(
      id: json['id'],
      employeeId: json['employee_id'],
      attendanceDate: json['attendance_date'],
      scheduleIn: json['schedule_in'],
      scheduleOut: json['schedule_out'],
      clockIn: json['clock_in'],
      clockOut: json['clock_out'],
      clockInLat: json['clock_in_lat'],
      clockInLng: json['clock_in_lng'],
      clockOutLat: json['clock_out_lat'],
      clockOutLng: json['clock_out_lng'],
      status: json['status'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
