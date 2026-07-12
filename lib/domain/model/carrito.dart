// lib/domain/model/carrito.dart
//
// Modelos Dart que mapean las tablas carrito_compras e items_carrito del backend.

class ItemCarritoModel {
  final int    idItem;
  final int    idCarrito;
  final int?   idMoto;
  final int?   idRepuesto;
  final int    cantidad;
  final double precioUnitario;
  final double subtotal;

  const ItemCarritoModel({
    required this.idItem,
    required this.idCarrito,
    this.idMoto,
    this.idRepuesto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ItemCarritoModel.fromJson(Map<String, dynamic> json) => ItemCarritoModel(
    idItem:         json['id_item']         as int,
    idCarrito:      json['id_carrito']      as int,
    idMoto:         json['id_moto']         as int?,
    idRepuesto:     json['id_repuesto']     as int?,
    cantidad:       json['cantidad']        as int,
    precioUnitario: double.parse(json['precio_unitario'].toString()),
    subtotal:       double.parse(json['subtotal'].toString()),
  );
}

class CarritoModel {
  final int                   idCarrito;
  final int                   idUsuarioCliente;
  final String                estado;
  final String                fechaCreacion;
  final List<ItemCarritoModel> items;
  final int                   numItems;
  final double                total;

  const CarritoModel({
    required this.idCarrito,
    required this.idUsuarioCliente,
    required this.estado,
    required this.fechaCreacion,
    required this.items,
    required this.numItems,
    required this.total,
  });

  factory CarritoModel.fromJson(Map<String, dynamic> json) => CarritoModel(
    idCarrito:        json['id_carrito']          as int,
    idUsuarioCliente: json['id_usuario_cliente']  as int,
    estado:           json['estado']              as String,
    fechaCreacion:    json['fecha_creacion']      as String,
    numItems:         json['num_items']           as int? ?? 0,
    total:            double.parse((json['total'] ?? 0).toString()),
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => ItemCarritoModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
