class Servicio {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precioBase;
  final int tiempoEstimadoMinutos;
  final bool estado;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Servicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precioBase,
    required this.tiempoEstimadoMinutos,
    required this.estado,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  Servicio copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precioBase,
    int? tiempoEstimadoMinutos,
    bool? estado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Servicio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioBase: precioBase ?? this.precioBase,
      tiempoEstimadoMinutos:
          tiempoEstimadoMinutos ?? this.tiempoEstimadoMinutos,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion:
          fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}