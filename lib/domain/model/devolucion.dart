// lib/domain/model/devolucion.dart

enum EstadoDevolucion {
  pendiente('Pendiente', 'Pendiente'),
  aprobada('Aprobada', 'Aprobada'),
  rechazada('Rechazada', 'Rechazada'),
  procesada('Procesada', 'Procesada');

  const EstadoDevolucion(this.value, this.label);
  final String value;
  final String label;

  static EstadoDevolucion fromValue(String v) =>
      EstadoDevolucion.values.firstWhere(
        (e) => e.value == v,
        orElse: () => EstadoDevolucion.pendiente,
      );
}

class Devolucion {
  final int idDevolucion;
  final int idVenta;
  final String motivo;
  final EstadoDevolucion estado;
  final double montoDevolucion;
  final DateTime? fechaSolicitud;
  final DateTime? fechaResolucion;

  const Devolucion({
    required this.idDevolucion,
    required this.idVenta,
    required this.motivo,
    required this.estado,
    required this.montoDevolucion,
    this.fechaSolicitud,
    this.fechaResolucion,
  });

  factory Devolucion.fromJson(Map<String, dynamic> j) => Devolucion(
        idDevolucion: j['id_devolucion'] as int,
        idVenta: j['id_venta'] as int,
        motivo: j['motivo']?.toString() ?? '',
        estado: EstadoDevolucion.fromValue(
          j['estado']?.toString() ?? 'Pendiente',
        ),
        montoDevolucion: double.parse(j['monto_devolucion'].toString()),
        fechaSolicitud: j['fecha_solicitud'] != null
            ? DateTime.tryParse(j['fecha_solicitud'].toString())
            : null,
        fechaResolucion: j['fecha_resolucion'] != null
            ? DateTime.tryParse(j['fecha_resolucion'].toString())
            : null,
      );

  Devolucion copyWith({
    int? idDevolucion,
    int? idVenta,
    String? motivo,
    EstadoDevolucion? estado,
    double? montoDevolucion,
    DateTime? fechaSolicitud,
    bool clearFechaSolicitud = false,
    DateTime? fechaResolucion,
    bool clearFechaResolucion = false,
  }) {
    return Devolucion(
      idDevolucion: idDevolucion ?? this.idDevolucion,
      idVenta: idVenta ?? this.idVenta,
      motivo: motivo ?? this.motivo,
      estado: estado ?? this.estado,
      montoDevolucion: montoDevolucion ?? this.montoDevolucion,
      fechaSolicitud: clearFechaSolicitud
          ? null
          : fechaSolicitud ?? this.fechaSolicitud,
      fechaResolucion: clearFechaResolucion
          ? null
          : fechaResolucion ?? this.fechaResolucion,
    );
  }
}

class PaginatedDevoluciones {
  final int count;
  final String? next;
  final String? previous;
  final List<Devolucion> results;

  const PaginatedDevoluciones({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedDevoluciones.fromJson(Map<String, dynamic> j) =>
      PaginatedDevoluciones(
        count: j['count'] as int,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) => Devolucion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
