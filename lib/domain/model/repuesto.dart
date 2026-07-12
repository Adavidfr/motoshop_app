// lib/domain/model/repuesto.dart

class Repuesto {
  final int idRepuesto;
  final String nombre;
  final String? descripcion;
  final String sku;
  final double costo;
  final double precioVenta;
  final int stock;
  final String estado;
  final String? imagen;
  final String fechaRegistro;

  const Repuesto({
    required this.idRepuesto,
    required this.nombre,
    this.descripcion,
    required this.sku,
    required this.costo,
    required this.precioVenta,
    required this.stock,
    required this.estado,
    this.imagen,
    required this.fechaRegistro,
  });

  factory Repuesto.fromJson(Map<String, dynamic> json) {
    double parsedCosto = 0.0;
    if (json['costo'] != null) {
      if (json['costo'] is num) {
        parsedCosto = (json['costo'] as num).toDouble();
      } else {
        parsedCosto = double.tryParse(json['costo'].toString()) ?? 0.0;
      }
    }

    double parsedPrecioVenta = 0.0;
    if (json['precio_venta'] != null) {
      if (json['precio_venta'] is num) {
        parsedPrecioVenta = (json['precio_venta'] as num).toDouble();
      } else {
        parsedPrecioVenta = double.tryParse(json['precio_venta'].toString()) ?? 0.0;
      }
    }

    return Repuesto(
      idRepuesto: json['id_repuesto'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      sku: json['sku'] as String,
      costo: parsedCosto,
      precioVenta: parsedPrecioVenta,
      stock: json['stock'] as int,
      estado: json['estado'] as String,
      imagen: json['imagen'] as String?,
      fechaRegistro: json['fecha_registro'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_repuesto': idRepuesto,
        'nombre': nombre,
        'descripcion': descripcion,
        'sku': sku,
        'costo': costo,
        'precio_venta': precioVenta,
        'stock': stock,
        'estado': estado,
        'imagen': imagen,
        'fecha_registro': fechaRegistro,
      };

  Map<String, dynamic> toSaveJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'sku': sku,
        'costo': costo,
        'precio_venta': precioVenta,
        'stock': stock,
        'estado': estado,
      };

  Repuesto copyWith({
    int? idRepuesto,
    String? nombre,
    String? descripcion,
    String? sku,
    double? costo,
    double? precioVenta,
    int? stock,
    String? estado,
    String? imagen,
    String? fechaRegistro,
  }) =>
      Repuesto(
        idRepuesto: idRepuesto ?? this.idRepuesto,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        sku: sku ?? this.sku,
        costo: costo ?? this.costo,
        precioVenta: precioVenta ?? this.precioVenta,
        stock: stock ?? this.stock,
        estado: estado ?? this.estado,
        imagen: imagen ?? this.imagen,
        fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      );
}
