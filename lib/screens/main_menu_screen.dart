import 'package:flutter/material.dart';
import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/core/storage.dart';
import 'package:pos_azmi/helpers/attendance_auto.dart';
import 'package:pos_azmi/models/outlet_model.dart';
import 'package:pos_azmi/screens/choose_outlet_screen.dart';
import 'package:pos_azmi/screens/kasir/kasir_screen.dart';
import 'package:pos_azmi/screens/login_screen.dart';
import 'package:pos_azmi/screens/absensi/absensi_karyawan_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final Outlet? outlet;

  const MainMenuScreen({super.key, this.outlet});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  Outlet? _currentOutlet;
  String outletText = 'Pilih Outlet';
  bool showOutletMenu = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOutletData();
  }

  Future<void> _loadOutletData() async {
    setState(() {
      loading = true;
    });

    try {
      final savedOutlet = await Storage.getOutlet();
      final res = await ApiClient.dio.get('/user/outlet');
      final List data = res.data['data'];

      final outlets = data.map((e) => Outlet.fromJson(e)).toList();

      if (savedOutlet != null) {
        _currentOutlet = savedOutlet;
      } else if (outlets.length == 1) {
        _currentOutlet = outlets.first;
        await Storage.saveOutlet(_currentOutlet!);
      }

      setState(() {
        outletText = _currentOutlet != null ? 'Pindah Outlet' : 'Pilih Outlet';
        showOutletMenu = outlets.length > 1;
        loading = false;
      });
    } catch (e) {
      setState(() {
        showOutletMenu = false;
        loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Storage.clearAll();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  List<Map<String, dynamic>> get mainMenuItems {
    return [
      if (_currentOutlet != null)
        {
          'icon': Icons.point_of_sale,
          'title': 'Kasir',
          'onTap': () {
            // kirim absensi otomatis
            AutoAttendance.submitAutoAbsensi();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KasirScreen(outlet: _currentOutlet!),
              ),
            );
          },
        },
      {
        'icon': Icons.access_time_filled,
        'title': 'Absensi Karyawan',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AbsensiKaryawanScreen(),
            ),
          );
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentOutlet != null
              ? 'Outlet - ${_currentOutlet!.name}'
              : 'Pilih Outlet',
        ),
        automaticallyImplyLeading: false,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOutletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Menu Utama',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    for (var item in mainMenuItems) ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(item['icon']),
                          title: Text(item['title']),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: item['onTap'],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (showOutletMenu) ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.store),
                          title: Text(outletText),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChooseOutletScreen(),
                              ),
                            );
                            _loadOutletData();
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Logout'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _logout(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
