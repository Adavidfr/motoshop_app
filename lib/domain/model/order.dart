// lib/domain/model/order.dart

enum OrderStatus {
  pending('pending', 'Pendiente'),
  confirmed('confirmed', 'Confirmado'),
  shipped('shipped', 'Enviado'),
  delivered('delivered', 'Entregado'),
  cancelled('cancelled', 'Cancelado');

  final String value;
  final String label;

  const OrderStatus(this.value, this.label);

  factory OrderStatus.fromValue(String val) {
    return OrderStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItem {
  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final idMoto = json['id_moto'] as int?;
    final idRepuesto = json['id_repuesto'] as int?;
    final name = idMoto != null ? 'Moto #$idMoto' : 'Repuesto #$idRepuesto';
    return OrderItem(
      id: json['id_item'] as int,
      productName: name,
      quantity: json['cantidad'] as int,
      unitPrice: double.parse(json['precio_unitario'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class Order {
  final int id;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String username;
  final int numItems;
  final double total;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.username,
    required this.numItems,
    required this.total,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final carritoJson = json['carrito'] as Map<String, dynamic>? ?? {};
    final itemsList = carritoJson['items'] as List<dynamic>? ?? [];
    final date = DateTime.parse(json['fecha_pedido'] as String);

    return Order(
      id: json['id_pedido'] as int,
      status: OrderStatus.fromValue(json['estado'] as String? ?? 'pending'),
      createdAt: date,
      updatedAt: date,
      username: json['username_cliente'] as String? ?? 'Desconocido',
      numItems: carritoJson['num_items'] as int? ?? 0,
      total: double.parse(json['total']?.toString() ?? '0.0'),
      items: itemsList.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Order copyWith({
    int? id,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    int? numItems,
    double? total,
    List<OrderItem>? items,
  }) => Order(
    id: id ?? this.id,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    username: username ?? this.username,
    numItems: numItems ?? this.numItems,
    total: total ?? this.total,
    items: items ?? this.items,
  );
}
