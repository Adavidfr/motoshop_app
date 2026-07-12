import '../../../domain/model/compra.dart';

class CompraDto {
  final int idCompra;
  final int proveedorId;
  final int? motoId;
  final int? repuestoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final DateTime? fechaCompra;
  final String estado;

  const CompraDto({
    required this.idCompra,
    required this.proveedorId,
    this.motoId,
    this.repuestoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.fechaCompra,
    required this.estado,
  });

  factory CompraDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompraDto(
      idCompra: _toInt(json['id_compra']),
      proveedorId: _toInt(json['proveedor']),
      motoId: _toNullableInt(json['moto']),
      repuestoId: _toNullableInt(
        json['repuesto'],
      ),
      cantidad: _toInt(json['cantidad']),
      precioUnitario: _toDouble(
        json['precio_unitario'],
      ),
      subtotal: _toDouble(json['subtotal']),
      fechaCompra: _toDateTime(
        json['fecha_compra'],
      ),
      estado: json['estado']?.toString() ??
          'Pendiente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proveedor': proveedorId,
      'moto': motoId,
      'repuesto': repuestoId,
      'cantidad': cantidad,
      'precio_unitario':
          precioUnitario.toStringAsFixed(2),
      'subtotal': subtotal.toStringAsFixed(2),
      'estado': estado,
    };
  }

  Compra toDomain() {
    return Compra(
      idCompra: idCompra,
      proveedorId: proveedorId,
      motoId: motoId,
      repuestoId: repuestoId,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: subtotal,
      fechaCompra: fechaCompra,
      estado: estado,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return _toInt(value);
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}