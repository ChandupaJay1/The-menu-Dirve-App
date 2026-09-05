class Order {
  final int id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
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
      totalAmount: double.tryParse(
              json['total_amount']?.toString() ??
                  json['total']?.toString() ??
                  '0') ??
          0.0,
      status: (json['status'] ?? 'assigned').toString(),
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
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
