class Promotion {
  final int id;
  final String name;
  final List<PromoCondition> conditions;
  final List<PromoReward> rewards;

  Promotion({
    required this.id,
    required this.name,
    required this.conditions,
    required this.rewards,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      name: json['name'],
      conditions: (json['conditions'] as List)
          .map((c) => PromoCondition.fromJson(c))
          .toList(),
      rewards: (json['rewards'] as List)
          .map((r) => PromoReward.fromJson(r))
          .toList(),
    );
  }
}

class PromoCondition {
  final int productId;
  final int? variantId;
  final int qtyRequired;

  PromoCondition({
    required this.productId,
    required this.variantId,
    required this.qtyRequired,
  });

  factory PromoCondition.fromJson(Map<String, dynamic> json) {
    return PromoCondition(
      productId: json['product_id'],
      variantId: json['product_variant_id'],
      qtyRequired: json['qty_required'],
    );
  }
}

class PromoReward {
  final int productId;
  final int? variantId;
  final int qtyRewarded;
  final int discountPercent;

  PromoReward({
    required this.productId,
    required this.variantId,
    required this.qtyRewarded,
    required this.discountPercent,
  });

  factory PromoReward.fromJson(Map<String, dynamic> json) {
    return PromoReward(
      productId: json['product_id'],
      variantId: json['product_variant_id'],
      qtyRewarded: json['qty_rewarded'],
      discountPercent: json['discount_percent'],
    );
  }
}
