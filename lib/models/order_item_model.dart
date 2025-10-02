import 'product_model.dart';

class OrderItemModel {
  final int id;
  final String name;
  final String sku;
  final String image;
  final int price;
  final String unit;
  final String category;
  final int quantity;
  final int total;
  final int? stock;
  final String? note;
  final List<ProductVariantModel> variants;

  OrderItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.image,
    required this.price,
    required this.unit,
    required this.category,
    required this.quantity,
    required this.total,
    this.stock,
    required this.note,
    required this.variants,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      image: json['image'],
      price: json['price'],
      unit: json['unit'],
      category: json['category'],
      quantity: json['quantity'] ?? 1,
      total: json['total'] ?? json['price'],
      stock: json['stock'],
      note: json['note'],
      variants: (json['variants'] as List?)
              ?.map((v) => ProductVariantModel.fromJson(v))
              .toList() ??
          [],
    );
  }
}
