class CartItem {
  final int productId;
  final String productName;
  final int productPrice;
  final int? variantId;
  final String? variantName;
  int quantity;
  final String? note;
  final bool isBonus;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.variantId,
    this.variantName,
    this.quantity = 1,
    this.note,
    this.isBonus = false,
  });

  int get subtotal => productPrice * quantity;

  Map<String, dynamic> toJson() => {
        "product_id": productId,
        "product_name": productName,
        "product_price": productPrice,
        "variant_id": variantId,
        "variant_name": variantName,
        "quantity": quantity,
        "subtotal": subtotal,
        "note": note,
        "is_bonus": isBonus,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json["product_id"],
        productName: json["product_name"],
        productPrice: json["product_price"],
        variantId: json["variant_id"],
        variantName: json["variant_name"],
        quantity: json["quantity"],
        note: json["note"],
        isBonus: json["is_bonus"] ?? false,
      );
}
