class Order {
  final int id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double? latitude;
  final double? longitude;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.latitude,
    this.longitude,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderNumber: (json['order_number'] ??
              json['order_no'] ??
              json['code'] ??
              'ORD-${json['id']}')
          .toString(),
      customerName: (json['customer_name'] ??
              json['customer']?['name'] ??
              json['name'] ??
              'Customer')
          .toString(),
      customerPhone: (json['customer_phone'] ??
              json['customer']?['phone'] ??
              json['phone'] ??
              '-')
          .toString(),
      deliveryAddress:
          (json['delivery_address'] ?? json['address'] ?? 'Delivery Address')
              .toString(),
      latitude: double.tryParse(
          (json['latitude'] ?? json['lat'] ?? json['delivery_latitude'] ?? '')
              .toString()),
      longitude: double.tryParse(
          (json['longitude'] ?? json['lng'] ?? json['delivery_longitude'] ?? '')
              .toString()),
      totalAmount: double.tryParse(
              json['total_amount']?.toString() ??
                  json['total']?.toString() ??
                  '0') ??
          0.0,
      status: ((json['status'] ?? 'on_delivery').toString().toLowerCase() == 'assigned')
          ? 'on_delivery'
          : (json['status'] ?? 'on_delivery').toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ??
              DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'latitude': latitude,
      'longitude': longitude,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
