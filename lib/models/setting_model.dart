class Setting {
  final String name;
  final String logo;
  final String phone;
  final String address;

  Setting({
    required this.name,
    required this.logo,
    required this.phone,
    required this.address,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      name: json['name'],
      logo: json['logo'],
      phone: json['phone'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logo': logo,
      'phone': phone,
      'address': address,
    };
  }
}
