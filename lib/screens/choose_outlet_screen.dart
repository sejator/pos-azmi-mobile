import 'package:flutter/material.dart';
import 'package:pos_azmi/helpers/notifikasi_helper.dart';
import 'package:pos_azmi/screens/main_menu_screen.dart';
import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/outlet_model.dart';

class ChooseOutletScreen extends StatefulWidget {
  const ChooseOutletScreen({super.key});

  @override
  State<ChooseOutletScreen> createState() => _ChooseOutletScreenState();
}

class _ChooseOutletScreenState extends State<ChooseOutletScreen> {
  List<Outlet> outlets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOutlets();
  }

  Future<void> _fetchOutlets() async {
    try {
      final res = await ApiClient.dio.get('/user/outlet');

      if (!mounted) return;

      final List data = res.data['data'];

      final List<Outlet> loaded = data.map((item) {
        return Outlet.fromJson(item);
      }).toList();

      setState(() {
        outlets = loaded;
        loading = false;
      });

      if (loaded.length == 1) {
        _selectOutlet(loaded.first);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      showSnackbar(
        context,
        'Gagal memuat outlet',
        backgroundColor: Colors.red,
      );
    }
  }

  void _selectOutlet(Outlet outlet) async {
    await Storage.saveOutlet(outlet);

    if (!mounted) return;

    showSnackbar(
      context,
      'Outlet "${outlet.name}" berhasil dipilih',
      icon: const Icon(Icons.check, color: Colors.white, size: 20),
      backgroundColor: Colors.green,
    );

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainMenuScreen(outlet: outlet)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Outlet')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOutlets,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: outlets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final outlet = outlets[index];
                  return InkWell(
                    onTap: () => _selectOutlet(outlet),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.store,
                                size: 32, color: Colors.red),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    outlet.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    outlet.address ?? '-',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    outlet.phone ?? '-',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
