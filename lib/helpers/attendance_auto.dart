import 'package:geolocator/geolocator.dart';
import 'package:pos_azmi/services/attendance_service.dart';

class AutoAttendance {
  static Future<bool> submitAutoAbsensi() async {
    try {
      // cek permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await AttendanceService.postAttendance(
        pos.latitude.toString(),
        pos.longitude.toString(),
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
