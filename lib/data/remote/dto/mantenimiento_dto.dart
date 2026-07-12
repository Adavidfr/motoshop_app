import '../../../domain/model/mantenimiento.dart';

class MantenimientoDto {
  final int idMantenimiento;
  final int motoId;
  final int usuarioClienteId;
  final int servicioId;
  final int kilometrajeActual;
  final String? diagnosticoInicial;
  final double costoFinal;
  final String estado;
  final DateTime? fechaRegistro;

  const MantenimientoDto({
    required this.idMantenimiento,
    required this.motoId,
    required this.usuarioClienteId,
    required this.servicioId,
    required this.kilometrajeActual,
    this.diagnosticoInicial,
    required this.costoFinal,
    required this.estado,
    this.fechaRegistro,
  });

  factory MantenimientoDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return MantenimientoDto(
      idMantenimiento:
          _toInt(json['id_mantenimiento']),
      motoId: _toInt(json['moto']),
      usuarioClienteId:
          _toInt(json['usuario_cliente']),
      servicioId: _toInt(json['servicio']),
      kilometrajeActual:
          _toInt(json['kilometraje_actual']),
      diagnosticoInicial:
          _toNullableString(
        json['diagnostico_inicial'],
      ),
      costoFinal:
          _toDouble(json['costo_final']),
      estado:
          json['estado']?.toString() ?? 'Pendiente',
      fechaRegistro:
          _toDateTime(json['fecha_registro']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moto': motoId,
      'usuario_cliente': usuarioClienteId,
      'servicio': servicioId,
      'kilometraje_actual': kilometrajeActual,
      'diagnostico_inicial': diagnosticoInicial,
      'costo_final': costoFinal.toStringAsFixed(2),
      'estado': estado,
    };
  }

  Mantenimiento toDomain() {
    return Mantenimiento(
      idMantenimiento: idMantenimiento,
      motoId: motoId,
      usuarioClienteId: usuarioClienteId,
      servicioId: servicioId,
      kilometrajeActual: kilometrajeActual,
      diagnosticoInicial: diagnosticoInicial,
      costoFinal: costoFinal,
      estado: estado,
      fechaRegistro: fechaRegistro,
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

    return DateTime.tryParse(value.toString());
  }

  static String? _toNullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }
}