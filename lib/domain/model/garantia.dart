// lib/domain/model/garantia.dart

enum EstadoGarantia {
  activa('Activa', 'Activa'),
  expirada('Expirada', 'Expirada'),
  cancelada('Cancelada', 'Cancelada'),
  enProceso('En proceso', 'En proceso');

  const EstadoGarantia(this.value, this.label);
  final String value;
  final String label;

  static EstadoGarantia fromValue(String v) =>
      EstadoGarantia.values.firstWhere(
        (e) => e.value == v,
        orElse: () => EstadoGarantia.activa,
      );
}

class Garantia {
  final int idGarantia;
  final int idVenta;
  final int idMoto;
  final int mesesGarantia;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? descripcion;
  final EstadoGarantia estado;

  const Garantia({
    required this.idGarantia,
    required this.idVenta,
    required this.idMoto,
    required this.mesesGarantia,
    this.fechaInicio,
    this.fechaFin,
    this.descripcion,
    required this.estado,
  });

  factory Garantia.fromJson(Map<String, dynamic> j) => Garantia(
        idGarantia: j['id_garantia'] as int? ?? 0,
        idVenta: j['id_venta'] as int? ?? 0,
        idMoto: j['id_moto'] as int? ?? 0,
        mesesGarantia: j['meses_garantia'] as int? ?? 0,
        fechaInicio: j['fecha_inicio'] != null
            ? DateTime.tryParse(j['fecha_inicio'].toString())
            : null,
        fechaFin: j['fecha_fin'] != null
            ? DateTime.tryParse(j['fecha_fin'].toString())
            : null,
        descripcion: j['descripcion'] as String?,
        estado: EstadoGarantia.fromValue(j['estado']?.toString() ?? 'Activa'),
      );

  Garantia copyWith({
    int? idGarantia,
    int? idVenta,
    int? idMoto,
    int? mesesGarantia,
    DateTime? fechaInicio,
    bool clearFechaInicio = false,
    DateTime? fechaFin,
    bool clearFechaFin = false,
    String? descripcion,
    bool clearDescripcion = false,
    EstadoGarantia? estado,
  }) {
    return Garantia(
      idGarantia: idGarantia ?? this.idGarantia,
      idVenta: idVenta ?? this.idVenta,
      idMoto: idMoto ?? this.idMoto,
      mesesGarantia: mesesGarantia ?? this.mesesGarantia,
      fechaInicio: clearFechaInicio ? null : fechaInicio ?? this.fechaInicio,
      fechaFin: clearFechaFin ? null : fechaFin ?? this.fechaFin,
      descripcion: clearDescripcion ? null : descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
    );
  }
}

class PaginatedGarantias {
  final int count;
  final String? next;
  final String? previous;
  final List<Garantia> results;

  const PaginatedGarantias({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedGarantias.fromJson(Map<String, dynamic> j) =>
      PaginatedGarantias(
        count: j['count'] as int? ?? 0,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) => Garantia.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
