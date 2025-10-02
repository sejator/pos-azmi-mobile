import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pos_azmi/models/attendance_daily.dart';
import 'package:pos_azmi/models/schedule.dart';
import 'package:pos_azmi/services/attendance_service.dart';
import 'package:geocoding/geocoding.dart';

class AbsensiKaryawanScreen extends StatefulWidget {
  const AbsensiKaryawanScreen({super.key});

  @override
  State<AbsensiKaryawanScreen> createState() => _AbsensiKaryawanScreenState();
}

class _AbsensiKaryawanScreenState extends State<AbsensiKaryawanScreen> {
  bool loading = false;
  AttendanceDaily? data;
  String? locationIn;
  String? locationOut;
  Schedule? schedule;
  final Map<String, String> addressCache = {};

  @override
  void initState() {
    super.initState();
    _getSchedule();
    _getAbsen();
  }

  Future<void> _getSchedule() async {
    setState(() => loading = true);
    try {
      final result = await AttendanceService.fetchSchedule();
      if (!mounted) return;
      setState(() => schedule = result);
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _getAbsen() async {
    setState(() => loading = true);
    try {
      final res = await AttendanceService.fetchAttendanceDaily();

      if (res?.clockInLat != null && res?.clockInLng != null) {
        final lat = double.tryParse(res!.clockInLat!);
        final lng = double.tryParse(res.clockInLng!);
        if (lat != null && lng != null) {
          locationIn = await _getAddressName(lat, lng);
        }
      }

      if (res?.clockOutLat != null && res?.clockOutLng != null) {
        final lat = double.tryParse(res!.clockOutLat!);
        final lng = double.tryParse(res.clockOutLng!);
        if (lat != null && lng != null) {
          locationOut = await _getAddressName(lat, lng);
        }
      }

      if (!mounted) return;
      setState(() => data = res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data absensi')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String> _getAddressName(double lat, double lng) async {
    final key = '$lat:$lng';
    if (addressCache.containsKey(key)) return addressCache[key]!;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            '${place.street}, ${place.subLocality}, ${place.locality}';
        addressCache[key] = address;
        return address;
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
    }
    return 'Alamat tidak ditemukan';
  }

  Future<void> _submitAbsen(double lat, double lng) async {
    setState(() => loading = true);
    try {
      await AttendanceService.postAttendance(lat.toString(), lng.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absen berhasil!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal melakukan absen')),
      );
    } finally {
      await _getAbsen();
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildAbsenInfo(String title, String? time, String? locationName,
      {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(time ?? '-', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            if (locationName != null)
              Text(
                locationName,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMapAndAbsen() async {
    setState(() => loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;

        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Aktifkan di pengaturan.',
              ),
            ),
          );
          return;
        }
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi diperlukan')),
          );
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final result = await showDialog<LatLng>(
        context: context,
        builder: (context) {
          LatLng selectedPosition = LatLng(pos.latitude, pos.longitude);

          return AlertDialog(
            title: const Text("Konfirmasi Lokasi Absen"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return FlutterMap(
                    options: MapOptions(
                      initialCenter: selectedPosition,
                      initialZoom: 17,
                      onTap: (tapPosition, point) {
                        setModalState(() {
                          selectedPosition = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                        userAgentPackageName: 'com.azmiproject.pos_azmi',
                      ),
                      const RichAttributionWidget(
                        showFlutterMapAttribution: false,
                        attributions: [
                          TextSourceAttribution('Google Maps'),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedPosition,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedPosition),
                child: const Text("Absen di Sini"),
              ),
            ],
          );
        },
      );

      if (result != null && mounted) {
        await _submitAbsen(result.latitude, result.longitude);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan lokasi')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildMap(double lat, double lng, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                  userAgentPackageName: 'com.azmiproject.pos_azmi',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      child: Icon(Icons.location_on, color: color, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final clockIn = data?.clockIn ?? '-';
    final clockOut = data?.clockOut ?? '-';
    final status = data?.status ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Karyawan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                _buildAbsenInfo(
                  'Absen Masuk',
                  clockIn,
                  locationIn,
                  color: status == 'late'
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                ),
                const SizedBox(width: 12),
                _buildAbsenInfo(
                  'Absen Keluar',
                  clockOut,
                  locationOut,
                ),
              ],
            ),
            if ((data?.clockInLat != null && data?.clockInLng != null) ||
                (data?.clockOutLat != null && data?.clockOutLng != null))
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    if (data?.clockInLat != null && data?.clockInLng != null)
                      Expanded(
                        child: _buildMap(
                          double.parse(data!.clockInLat!),
                          double.parse(data!.clockInLng!),
                          Colors.green,
                        ),
                      ),
                    if (data?.clockOutLat != null &&
                        data?.clockOutLng != null) ...[
                      if (data?.clockInLat != null) const SizedBox(width: 12),
                      Expanded(
                        child: _buildMap(
                          double.parse(data!.clockOutLat!),
                          double.parse(data!.clockOutLng!),
                          Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const Spacer(),
            if (schedule != null)
              Text(
                '${schedule!.name} (${schedule!.startTime} - ${schedule!.endTime})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : _showMapAndAbsen,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.location_on),
                label: Text(loading ? 'Memproses...' : 'Absen Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
