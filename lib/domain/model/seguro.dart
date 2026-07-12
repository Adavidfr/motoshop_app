// lib/domain/model/seguro.dart

enum TipoCobertura {
  basica('Básica', 'Básica'),
  completa('Completa', 'Completa'),
  terceros('Terceros', 'Terceros'),
  todosRiesgos('Todos los riesgos', 'Todos los riesgos');

  const TipoCobertura(this.value, this.label);
  final String value;
  final String label;

  static TipoCobertura fromValue(String v) =>
      TipoCobertura.values.firstWhere(
        (t) => t.value == v,
        orElse: () => TipoCobertura.basica,
      );
}

enum EstadoSeguro {
  activo('Activo', 'Activo'),
  vencido('Vencido', 'Vencido'),
  cancelado('Cancelado', 'Cancelado'),
  pendiente('Pendiente', 'Pendiente');

  const EstadoSeguro(this.value, this.label);
  final String value;
  final String label;

  static EstadoSeguro fromValue(String v) =>
      EstadoSeguro.values.firstWhere(
        (e) => e.value == v,
        orElse: () => EstadoSeguro.pendiente,
      );
}

class Seguro {
  final int idSeguro;
  final int idVenta;
  final String aseguradora;
  final String numeroPoliza;
  final TipoCobertura tipoCobertura;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double costoAnual;
  final EstadoSeguro estado;

  const Seguro({
    required this.idSeguro,
    required this.idVenta,
    required this.aseguradora,
    required this.numeroPoliza,
    required this.tipoCobertura,
    this.fechaInicio,
    this.fechaFin,
    required this.costoAnual,
    required this.estado,
  });

  factory Seguro.fromJson(Map<String, dynamic> j) => Seguro(
        idSeguro: j['id_seguro'] as int,
        idVenta: j['id_venta'] as int,
        aseguradora: j['aseguradora']?.toString() ?? '',
        numeroPoliza: j['numero_poliza']?.toString() ?? '',
        tipoCobertura: TipoCobertura.fromValue(
          j['tipo_cobertura']?.toString() ?? 'Básica',
        ),
        fechaInicio: j['fecha_inicio'] != null
            ? DateTime.tryParse(j['fecha_inicio'].toString())
            : null,
        fechaFin: j['fecha_fin'] != null
            ? DateTime.tryParse(j['fecha_fin'].toString())
            : null,
        costoAnual: double.parse(j['costo_anual'].toString()),
        estado: EstadoSeguro.fromValue(
          j['estado']?.toString() ?? 'Pendiente',
        ),
      );

  Seguro copyWith({
    int? idSeguro,
    int? idVenta,
    String? aseguradora,
    String? numeroPoliza,
    TipoCobertura? tipoCobertura,
    DateTime? fechaInicio,
    bool clearFechaInicio = false,
    DateTime? fechaFin,
    bool clearFechaFin = false,
    double? costoAnual,
    EstadoSeguro? estado,
  }) {
    return Seguro(
      idSeguro: idSeguro ?? this.idSeguro,
      idVenta: idVenta ?? this.idVenta,
      aseguradora: aseguradora ?? this.aseguradora,
      numeroPoliza: numeroPoliza ?? this.numeroPoliza,
      tipoCobertura: tipoCobertura ?? this.tipoCobertura,
      fechaInicio: clearFechaInicio ? null : fechaInicio ?? this.fechaInicio,
      fechaFin: clearFechaFin ? null : fechaFin ?? this.fechaFin,
      costoAnual: costoAnual ?? this.costoAnual,
      estado: estado ?? this.estado,
    );
  }
}

class PaginatedSeguros {
  final int count;
  final String? next;
  final String? previous;
  final List<Seguro> results;

  const PaginatedSeguros({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedSeguros.fromJson(Map<String, dynamic> j) =>
      PaginatedSeguros(
        count: j['count'] as int,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) => Seguro.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
