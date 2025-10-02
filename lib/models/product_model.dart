class ProductResponseModel {
  final List<ProductModel> products;
  final PaginationModel pagination;

  ProductResponseModel({
    required this.products,
    required this.pagination,
  });

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ProductResponseModel(
      products: (data['products'] as List?)
              ?.map((item) => ProductModel.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationModel.fromJson(data['pagination'] ?? {}),
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final String sku;
  final String image;
  final int price;
  final int? stock;
  final String unit;
  final String category;
  final List<ProductVariantModel> variants;

  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.image,
    required this.price,
    this.stock,
    required this.unit,
    required this.category,
    required this.variants,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      image: json['image'],
      price: json['price'],
      stock: json.containsKey('stock') ? json['stock'] : null,
      unit: json['unit'],
      category: json['category'],
      variants: (json['variants'] as List?)
              ?.map((v) => ProductVariantModel.fromJson(v))
              .toList() ??
          [],
    );
  }
}

class ProductVariantModel {
  final int id;
  final int productId;
  final String name;
  final int price;
  final int? stock;

  ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.stock,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      price: json['price'],
      stock: json.containsKey('stock') ? json['stock'] : null,
    );
  }
}

class PaginationModel {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  PaginationModel({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
    );
  }
}
