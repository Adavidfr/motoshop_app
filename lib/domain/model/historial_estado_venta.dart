// lib/domain/model/historial_estado_venta.dart

class HistorialEstadoVenta {
  final int idHistorial;
  final int idVenta;
  final String? estadoAnterior;
  final String estadoNuevo;
  final DateTime? fechaCambio;
  final String? observacion;

  const HistorialEstadoVenta({
    required this.idHistorial,
    required this.idVenta,
    this.estadoAnterior,
    required this.estadoNuevo,
    this.fechaCambio,
    this.observacion,
  });

  factory HistorialEstadoVenta.fromJson(Map<String, dynamic> j) =>
      HistorialEstadoVenta(
        idHistorial: j['id_historial'] as int? ?? 0,
        idVenta: j['id_venta'] as int? ?? 0,
        estadoAnterior: j['estado_anterior'] as String?,
        estadoNuevo: j['estado_nuevo']?.toString() ?? '',
        fechaCambio: j['fecha_cambio'] != null
            ? DateTime.tryParse(j['fecha_cambio'].toString())
            : null,
        observacion: j['observacion'] as String?,
      );

  HistorialEstadoVenta copyWith({
    int? idHistorial,
    int? idVenta,
    String? estadoAnterior,
    bool clearEstadoAnterior = false,
    String? estadoNuevo,
    DateTime? fechaCambio,
    bool clearFechaCambio = false,
    String? observacion,
    bool clearObservacion = false,
  }) {
    return HistorialEstadoVenta(
      idHistorial: idHistorial ?? this.idHistorial,
      idVenta: idVenta ?? this.idVenta,
      estadoAnterior: clearEstadoAnterior
          ? null
          : estadoAnterior ?? this.estadoAnterior,
      estadoNuevo: estadoNuevo ?? this.estadoNuevo,
      fechaCambio: clearFechaCambio ? null : fechaCambio ?? this.fechaCambio,
      observacion: clearObservacion ? null : observacion ?? this.observacion,
    );
  }
}

class PaginatedHistorialEstadoVenta {
  final int count;
  final String? next;
  final String? previous;
  final List<HistorialEstadoVenta> results;

  const PaginatedHistorialEstadoVenta({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedHistorialEstadoVenta.fromJson(Map<String, dynamic> j) =>
      PaginatedHistorialEstadoVenta(
        count: j['count'] as int? ?? 0,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) =>
                HistorialEstadoVenta.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
