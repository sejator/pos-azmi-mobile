import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/core/storage.dart';
import 'package:pos_azmi/helpers/format_helper.dart';
import 'package:pos_azmi/helpers/notifikasi_helper.dart';
import 'package:pos_azmi/models/payment_model.dart';
import 'package:pos_azmi/providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _tunaiController = TextEditingController();
  final TextEditingController _kembalianController = TextEditingController();
  bool _isFormatting = false;
  bool _isProcessing = false;

  List<PaymentMethod> metodePembayaran = [];
  PaymentMethod? selectedPayment;
  int grandTotal = 0;
  String selectedOrderType = 'takeaway';

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    grandTotal = cart.total;
    _loadMetodePembayaran();
    _tunaiController.addListener(_handleTunaiChange);
  }

  @override
  void dispose() {
    _tunaiController.removeListener(_handleTunaiChange);
    _tunaiController.dispose();
    _kembalianController.dispose();
    super.dispose();
  }

  Future<void> _loadMetodePembayaran() async {
    try {
      final res = await ApiClient.dio.get('/payments');
      final data = res.data['data'] as List<dynamic>;
      final loaded = data.map((item) => PaymentMethod.fromJson(item)).toList();

      setState(() {
        metodePembayaran = loaded;
        if (loaded.isNotEmpty) {
          selectedPayment = loaded.first;

          if (selectedPayment!.code.toLowerCase().contains('qris')) {
            _tunaiController.text = FormatHelper.toRupiah(grandTotal);
            _kembalianController.text = FormatHelper.toRupiah(0);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      showSnackbar(context, 'Gagal memuat metode pembayaran',
          backgroundColor: Colors.red);
    }
  }

  void _handleTunaiChange() {
    final isQRIS =
        selectedPayment?.code.toLowerCase().contains('qris') ?? false;
    if (_isFormatting || isQRIS) return;

    _isFormatting = true;
    final numeric = _tunaiController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final bayar = int.tryParse(numeric) ?? 0;
    final formatted = FormatHelper.toRupiah(bayar);

    _tunaiController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    final kembalian = bayar - grandTotal;
    _kembalianController.text = FormatHelper.toRupiah(kembalian);

    _isFormatting = false;

    setState(() {});
  }

  bool _isBayarButtonEnabled() {
    final bayar = int.tryParse(
          _tunaiController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (selectedPayment == null) return false;
    final isQRIS = selectedPayment!.code.toLowerCase().contains('qris');
    return grandTotal > 0 && (isQRIS || bayar >= grandTotal);
  }

  Future<void> createOrder() async {
    setState(() => _isProcessing = true);

    final bayar = int.tryParse(
          _tunaiController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final kembalian = bayar - grandTotal;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final outlet = await Storage.getOutlet();

    if (outlet == null || selectedPayment == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final user = await Storage.getUser();

    final payload = {
      "order_type": selectedOrderType,
      "sub_total": cart.total,
      "grand_total": grandTotal,
      "cash": bayar,
      "change": kembalian,
      "tax": 0,
      "discount": 0,
      "payment_method_id": selectedPayment!.id,
      "outlet_id": outlet.id,
      "source": "kasir",
      "user_id": user?.id,
      "is_process": true,
      "items": cart.items
          .map((item) => {
                "product_id": item.productId,
                "variant_id": item.variantId,
                "product_price": item.productPrice,
                "quantity": item.quantity,
                "subtotal": item.productPrice * item.quantity,
                if (item.note?.isNotEmpty == true) "note": item.note,
              })
          .toList(),
    };

    try {
      final res = await ApiClient.dio.post('/orders', data: payload);
      final invoice = res.data['data']['order']['invoice'];
      if (!mounted) return;

      cart.clear();
      Navigator.pushReplacementNamed(context, '/success', arguments: invoice);
    } catch (e) {
      if (!mounted) return;
      showSnackbar(context, 'Gagal membuat pesanan',
          backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isQRIS =
        selectedPayment?.code.toLowerCase().contains('qris') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRowLabel('Sub Total', FormatHelper.toRupiah(cart.total)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedOrderType,
              items: const [
                DropdownMenuItem(
                  value: 'dine_in',
                  child: Text('Dine In', style: TextStyle(color: Colors.black)),
                ),
                DropdownMenuItem(
                  value: 'takeaway',
                  child:
                      Text('Takeaway', style: TextStyle(color: Colors.black)),
                ),
                DropdownMenuItem(
                  value: 'delivery',
                  child:
                      Text('Delivery', style: TextStyle(color: Colors.black)),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => selectedOrderType = value);
              },
              decoration: const InputDecoration(
                labelText: 'Tipe Order',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
              value: selectedPayment,
              items: metodePembayaran.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.name,
                      style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPayment = value;
                  if (value?.code.toLowerCase().contains('qris') ?? false) {
                    _tunaiController.text = FormatHelper.toRupiah(grandTotal);
                    _kembalianController.text = FormatHelper.toRupiah(0);
                  } else {
                    _tunaiController.clear();
                    _kembalianController.clear();
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _buildRowLabel('Grand Total', FormatHelper.toRupiah(grandTotal)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tunaiController,
              keyboardType: TextInputType.number,
              enabled: !isQRIS,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Tunai',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: _kembalianController,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kembalianController.text.contains('-')
                    ? Colors.red
                    : Colors.green[700],
              ),
              decoration: InputDecoration(
                labelText: 'Kembalian',
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isBayarButtonEnabled() && !_isProcessing)
                    ? createOrder
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 45),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Bayar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowLabel(String label, String value) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        readOnly: true,
        initialValue: value,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
