// lib/domain/model/movimiento_inventario.dart

import 'moto.dart';
import 'repuesto.dart';
import 'user.dart';

class MovimientoInventario {
  final int idMovimiento;
  final Moto? moto;
  final Repuesto? repuesto;
  final int cantidad;
  final String tipoMovimiento;
  final String? descripcion;
  final String fechaMovimiento;
  final User usuario;

  const MovimientoInventario({
    required this.idMovimiento,
    this.moto,
    this.repuesto,
    required this.cantidad,
    required this.tipoMovimiento,
    this.descripcion,
    required this.fechaMovimiento,
    required this.usuario,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) => MovimientoInventario(
        idMovimiento: json['id_movimiento'] as int,
        moto: json['moto'] != null ? Moto.fromJson(json['moto'] as Map<String, dynamic>) : null,
        repuesto: json['repuesto'] != null
            ? Repuesto.fromJson(json['repuesto'] as Map<String, dynamic>)
            : null,
        cantidad: json['cantidad'] as int,
        tipoMovimiento: json['tipo_movimiento'] as String,
        descripcion: json['descripcion'] as String?,
        fechaMovimiento: json['fecha_movimiento'] as String,
        usuario: User.fromJson(json['usuario'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id_movimiento': idMovimiento,
        'id_moto': moto?.idMoto,
        'id_repuesto': repuesto?.idRepuesto,
        'cantidad': cantidad,
        'tipo_movimiento': tipoMovimiento,
        'descripcion': descripcion,
        'fecha_movimiento': fechaMovimiento,
        'usuario': usuario.toJson(),
      };
}
