import '../../../domain/model/repuesto_mantenimiento.dart';

class RepuestoMantenimientoDto {
  final int idRepuestoMantenimiento;
  final int mantenimientoId;
  final int repuestoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const RepuestoMantenimientoDto({
    required this.idRepuestoMantenimiento,
    required this.mantenimientoId,
    required this.repuestoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory RepuestoMantenimientoDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return RepuestoMantenimientoDto(
      idRepuestoMantenimiento:
          _toInt(json['id_repuesto_mantenimiento']),
      mantenimientoId:
          _toInt(json['mantenimiento']),
      repuestoId: _toInt(json['repuesto']),
      cantidad: _toInt(json['cantidad']),
      precioUnitario:
          _toDouble(json['precio_unitario']),
      subtotal: _toDouble(json['subtotal']),
    );
  }

  RepuestoMantenimiento toDomain() {
    return RepuestoMantenimiento(
      idRepuestoMantenimiento:
          idRepuestoMantenimiento,
      mantenimientoId: mantenimientoId,
      repuestoId: repuestoId,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: subtotal,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}