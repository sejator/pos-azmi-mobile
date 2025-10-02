class Outlet {
  final int id;
  final String name;
  final String? phone;
  final String? address;

  Outlet({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
