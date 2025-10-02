import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/models/order_model.dart';

class OrderService {
  static Future<OrderModel?> fetchOrderByInvoice(String invoice) async {
    try {
      final response = await ApiClient.dio.get('/orders/$invoice');

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final data = response.data['data'];
        final orderJson = data['order'];
        final order = OrderModel.fromJson(orderJson);
        return order;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  static Future<void> updateStatusInvoice(
      String invoice, Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.put(
        '/orders/$invoice',
        data: payload,
      );

      if (response.statusCode != 200 || response.data['ok'] != true) {
        throw Exception('Gagal update status');
      }
    } catch (e) {
      throw Exception('Gagal update status invoice');
    }
  }
}
