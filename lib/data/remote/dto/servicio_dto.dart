import '../../../domain/model/servicio.dart';

class ServicioDto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precioBase;
  final int tiempoEstimadoMinutos;
  final bool estado;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const ServicioDto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precioBase,
    required this.tiempoEstimadoMinutos,
    required this.estado,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory ServicioDto.fromJson(Map<String, dynamic> json) {
    return ServicioDto(
      id: _toInt(json['id']),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: _toNullableString(json['descripcion']),
      precioBase: _toDouble(json['precio_base']),
      tiempoEstimadoMinutos:
          _toInt(json['tiempo_estimado_minutos']),
      estado: json['estado'] as bool? ?? true,
      fechaCreacion: _toDateTime(json['fecha_creacion']),
      fechaActualizacion:
          _toDateTime(json['fecha_actualizacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_base': precioBase.toStringAsFixed(2),
      'tiempo_estimado_minutos': tiempoEstimadoMinutos,
      'estado': estado,
    };
  }

  Servicio toDomain() {
    return Servicio(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      precioBase: precioBase,
      tiempoEstimadoMinutos: tiempoEstimadoMinutos,
      estado: estado,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
    );
  }

  factory ServicioDto.fromDomain(Servicio servicio) {
    return ServicioDto(
      id: servicio.id,
      nombre: servicio.nombre,
      descripcion: servicio.descripcion,
      precioBase: servicio.precioBase,
      tiempoEstimadoMinutos:
          servicio.tiempoEstimadoMinutos,
      estado: servicio.estado,
      fechaCreacion: servicio.fechaCreacion,
      fechaActualizacion: servicio.fechaActualizacion,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }
}