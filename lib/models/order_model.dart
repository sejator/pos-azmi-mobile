import 'order_item_model.dart';

class OrderModel {
  final int id;
  final String invoice;
  final String orderDate;
  final String status;
  final String orderType;
  final int total;
  final int grandTotal;
  final int cash;
  final int change;
  final int tax;
  final int discount;
  final String noAntrian;
  final String paymentMethod;
  final String paymentStatus;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.invoice,
    required this.orderDate,
    required this.status,
    required this.orderType,
    required this.total,
    required this.grandTotal,
    required this.cash,
    required this.change,
    required this.tax,
    required this.discount,
    required this.noAntrian,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      invoice: json['invoice'],
      orderDate: json['order_date'],
      status: json['status'],
      orderType: json['order_type'],
      total: json['total'],
      grandTotal: json['grand_total'],
      cash: json['cash'],
      change: json['change'],
      tax: int.tryParse(json['tax'].toString()) ?? 0,
      discount: int.tryParse(json['discount'].toString()) ?? 0,
      noAntrian: json['no_antrian'] ?? '-',
      paymentMethod: json['payment_method'] ?? '-',
      paymentStatus: json['payment_status'] ?? '-',
      items: (json['items'] as List)
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
    );
  }
}
