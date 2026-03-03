class Driver {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? token;

  Driver({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.vehicleType,
    this.vehicleNumber,
    this.token,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      vehicleType: json['vehicle_type'],
      vehicleNumber: json['vehicle_number'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
    };
  }
}
