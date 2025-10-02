import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/models/attendance_daily.dart';
import 'package:pos_azmi/models/schedule.dart';

class AttendanceService {
  static Future<AttendanceDaily?> fetchAttendanceDaily() async {
    try {
      final response = await ApiClient.dio.get('/attendance/daily');

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final data = response.data['data'];
        return AttendanceDaily.fromJson(data);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  static Future<Schedule?> fetchSchedule() async {
    try {
      final response = await ApiClient.dio.get('/attendance/schedule');

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final data = response.data['data'];
        return Schedule.fromJson(data);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  static Future<void> postAttendance(String lat, String lng) async {
    try {
      await ApiClient.dio.post('/attendance', data: {
        'latitude': lat,
        'longitude': lng,
      });
    } catch (e) {
      throw Exception('Failed to post attendance: $e');
    }
  }
}
