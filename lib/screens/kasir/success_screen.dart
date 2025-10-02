import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:pos_azmi/core/storage.dart';
import 'package:pos_azmi/helpers/format_helper.dart';
import 'package:pos_azmi/helpers/notifikasi_helper.dart';
import 'package:pos_azmi/helpers/printer_helper.dart';
import 'package:pos_azmi/models/order_model.dart';
import 'package:pos_azmi/models/setting_model.dart';
import 'package:pos_azmi/services/order_service.dart';
import 'kasir_screen.dart';

class SuccessScreen extends StatefulWidget {
  final bool autoPrint;

  const SuccessScreen({super.key, this.autoPrint = true});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  OrderModel? order;
  Setting? setting;

  bool isPrinted = false;
  bool isConnecting = false;
  List<BluetoothDevice> availablePrinters = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is String) {
      _fetchOrderByInvoice(args);
    } else {
      Future.microtask(() {
        showSnackbar(
          context,
          'No. Order tidak valid',
          backgroundColor: Colors.red,
        );
        Navigator.pop(context);
      });
    }
  }

  Future<void> _fetchOrderByInvoice(String invoice) async {
    try {
      final fetchedOrder = await OrderService.fetchOrderByInvoice(invoice);
      final fetchedSetting = await Storage.getSetting();
      setState(() {
        order = fetchedOrder;
        setting = fetchedSetting;
      });

      if (widget.autoPrint) {
        Future.delayed(
            const Duration(milliseconds: 500), _checkPrinterAndPrint);
      }
    } catch (e) {
      if (!mounted) return;
      showSnackbar(
        context,
        'Gagal memuat data',
        backgroundColor: Colors.red,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _checkPrinterAndPrint() async {
    if (order == null) return;

    try {
      final savedPrinter = await Storage.getSavedPrinter();

      if (savedPrinter != null) {
        final device = BluetoothDevice(
          savedPrinter['name'] ?? '-',
          savedPrinter['address'] ?? '-',
        );

        try {
          setState(() => isConnecting = true);

          bool isConnected = await printer.isConnected ?? false;
          if (isConnected) {
            await printer.disconnect();
            await Future.delayed(const Duration(milliseconds: 300));
          }

          await printer.connect(device);
          await Future.delayed(const Duration(milliseconds: 500));

          await PrinterHelper.printReceipt(order!, setting);
          await Future.delayed(const Duration(milliseconds: 500));

          try {
            await OrderService.updateStatusInvoice(order!.invoice, {
              'is_process': true,
            });
          } catch (e) {
            _showErrorSnackbar('Update status invoice gagal.');
          }
          await printer.disconnect();

          setState(() {
            isPrinted = true;
            isConnecting = false;
          });
          return;
        } catch (e) {
          await printer.disconnect();
          await Storage.clearSavedPrinter();
          _showErrorSnackbar('Gagal koneksi ke printer. Silakan pilih ulang.');
        } finally {
          setState(() => isConnecting = false);
        }
      }

      List<BluetoothDevice> devices = [];
      try {
        devices = await printer.getBondedDevices();
      } catch (e) {
        _showErrorSnackbar('Bluetooth tidak tersedia di perangkat ini.');
        return;
      }

      setState(() => availablePrinters = devices);
      if (devices.isNotEmpty) {
        _showPrinterSelector();
      } else {
        _showErrorSnackbar('Tidak ada printer yang tersedia.');
      }
    } catch (e) {
      _showErrorSnackbar('Bluetooth tidak tersedia di perangkat ini.');
    }
  }

  Future<void> _printNow(BluetoothDevice device) async {
    if (order == null) return;

    try {
      setState(() => isConnecting = true);

      bool isConnected = await printer.isConnected ?? false;
      if (isConnected) {
        await printer.disconnect();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await printer.connect(device);
      await Future.delayed(const Duration(milliseconds: 500));

      await Storage.setPrinter(device.name ?? '-', device.address ?? '-');

      await PrinterHelper.printReceipt(order!, setting);
      await Future.delayed(const Duration(milliseconds: 500));

      await printer.disconnect();
      setState(() => isPrinted = true);
    } catch (e) {
      _showErrorSnackbar('Gagal mencetak, Pastikan printer terhubung.');
    } finally {
      setState(() => isConnecting = false);
    }
  }

  void _showPrinterSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 32,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Printer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...availablePrinters.map(
                (device) => Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(device.name ?? 'Unknown'),
                    subtitle: Text(device.address ?? '-'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _printNow(device);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    showSnackbar(
      context,
      message,
      icon: const Icon(Icons.error, color: Colors.white, size: 20),
      backgroundColor: Colors.red,
    );
  }

  Widget buildRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final date = DateTime.tryParse(order!.orderDate) ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Berhasil')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(setting?.name ?? "-",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(setting?.address ?? "-",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14)),
                  Text(setting?.phone ?? "-",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      order!.noAntrian,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const Divider(thickness: 1.5, color: Colors.grey),
                  buildRow("No. Pesanan", order!.invoice),
                  buildRow("Tanggal", DateFormat('dd-MM-yyyy').format(date)),
                  buildRow("Jam", DateFormat('HH:mm').format(date)),
                  buildRow("Metode Bayar", order!.paymentMethod),
                  const Divider(thickness: 1.5, color: Colors.grey),
                  ...order!.items.map((item) {
                    final name = item.name;
                    final qtyLine =
                        "${item.quantity} x ${FormatHelper.toRupiah(item.price)}";
                    final totalLine = FormatHelper.toRupiah(item.total);
                    final variantName =
                        item.variants.isNotEmpty ? "(${item.variants.first.name})" : "";
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$name $variantName"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(qtyLine),
                            Text(totalLine),
                          ],
                        ),
                        if (item.note?.isNotEmpty == true)
                          Text("- Catatan: ${item.note}"),
                        const SizedBox(height: 6),
                      ],
                    );
                  }),
                  const Divider(thickness: 1.5, color: Colors.grey),
                  buildRow("Subtotal", FormatHelper.toRupiah(order!.total)),
                  buildRow("Diskon", "-${order!.discount}"),
                  buildRow(
                      "Grand Total", FormatHelper.toRupiah(order!.grandTotal)),
                  buildRow("Tunai", FormatHelper.toRupiah(order!.cash)),
                  buildRow("Kembalian", FormatHelper.toRupiah(order!.change)),
                  const SizedBox(height: 16),
                  const Text("Terima kasih!",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Ulang'),
                    onPressed: _checkPrinterAndPrint,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali ke Transaksi'),
                    onPressed: () async {
                      final outlet = await Storage.getOutlet();
                      if (outlet != null && mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KasirScreen(
                              outlet: outlet,
                              initialTabIndex: 2,
                            ),
                          ),
                          (route) => false,
                        );
                      } else if (mounted) {
                        showSnackbar(
                          context,
                          'Outlet tidak ditemukan',
                          backgroundColor: Colors.red,
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                ],
              ),
            ),
          ),
          if (isConnecting)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text("Mencetak...",
                        style: TextStyle(color: Colors.white, fontSize: 12))
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
