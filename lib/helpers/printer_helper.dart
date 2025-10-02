import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:pos_azmi/helpers/format_helper.dart';
import 'package:pos_azmi/models/order_model.dart';
import 'package:pos_azmi/models/setting_model.dart';

class PrinterHelper {
  static Future<void> printReceipt(OrderModel order, Setting? setting) async {
    final printer = BlueThermalPrinter.instance;
    final isConnected = await printer.isConnected ?? false;

    if (!isConnected) {
      final devices = await printer.getBondedDevices();
      if (devices.isNotEmpty) {
        await printer.connect(devices.first);
      } else {
        return;
      }
    }

    final date = DateTime.tryParse(order.orderDate) ?? DateTime.now();
    final df = DateFormat('dd-MM-yyyy');
    final tf = DateFormat('HH:mm');

    printer.printNewLine();
    printer.printCustom(setting?.name ?? "-", 4, 1);
    printer.printCustom(setting?.address ?? "-", 0, 1);
    printer.printCustom(setting?.phone ?? "-", 0, 1);
    printer.printNewLine();
    printer.printCustom(order.noAntrian, 4, 1);
    printer.printNewLine();
    printer.printLeftRight("No. Pesanan", order.invoice, 0);
    printer.printLeftRight("Tanggal", df.format(date), 0);
    printer.printLeftRight("Jam", tf.format(date), 0);
    printer.printLeftRight("Metode Bayar", order.paymentMethod, 0);
    printer.printNewLine();
    printer.printCustom("--------------------------------", 0, 1);

    for (var item in order.items) {
      final qtyLine = "${item.quantity} x ${FormatHelper.toRupiah(item.price)}";
      final totalLine = FormatHelper.toRupiah(item.total);
      final variantName =
          item.variants.isNotEmpty ? "(${item.variants.first.name})" : "";
      printer.printCustom("${item.name} $variantName", 0, 0);
      printer.printLeftRight(qtyLine, totalLine, 0);
      if (item.note?.isNotEmpty == true) {
        printer.printCustom("- Catatan: ${item.note}", 0, 0);
      }
    }

    printer.printCustom("--------------------------------", 0, 1);
    printer.printNewLine();
    printer.printLeftRight("Subtotal", FormatHelper.toRupiah(order.total), 0);
    printer.printLeftRight("Diskon", "-${order.discount}", 0);
    printer.printLeftRight(
        "Grand Total", FormatHelper.toRupiah(order.grandTotal), 0);
    printer.printLeftRight("Tunai", FormatHelper.toRupiah(order.cash), 0);
    printer.printLeftRight("Kembalian", FormatHelper.toRupiah(order.change), 0);
    printer.printNewLine();
    printer.printCustom("Terima kasih!", 1, 1);
    printer.printNewLine();
    printer.printCustom("Powered by @alkhatech.id", 0, 1);
    printer.printNewLine();
    printer.paperCut();
  }
}
