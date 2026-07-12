// lib/domain/model/pago.dart

enum MetodoPago {
  efectivo('Efectivo', 'Efectivo'),
  tarjeta('Tarjeta', 'Tarjeta'),
  transferencia('Transferencia', 'Transferencia'),
  cheque('Cheque', 'Cheque');

  const MetodoPago(this.value, this.label);
  final String value;
  final String label;

  static MetodoPago fromValue(String v) => MetodoPago.values.firstWhere(
        (m) => m.value == v,
        orElse: () => MetodoPago.efectivo,
      );
}

enum EstadoPago {
  pendiente('Pendiente', 'Pendiente'),
  completado('Completado', 'Completado'),
  fallido('Fallido', 'Fallido'),
  reembolsado('Reembolsado', 'Reembolsado');

  const EstadoPago(this.value, this.label);
  final String value;
  final String label;

  static EstadoPago fromValue(String v) => EstadoPago.values.firstWhere(
        (e) => e.value == v,
        orElse: () => EstadoPago.pendiente,
      );
}

class Pago {
  final int idPago;
  final int idVenta;
  final double monto;
  final MetodoPago metodoPago;
  final EstadoPago estado;
  final DateTime? fechaPago;
  final String? referencia;

  const Pago({
    required this.idPago,
    required this.idVenta,
    required this.monto,
    required this.metodoPago,
    required this.estado,
    this.fechaPago,
    this.referencia,
  });

  factory Pago.fromJson(Map<String, dynamic> j) => Pago(
        idPago: j['id_pago'] as int,
        idVenta: j['id_venta'] as int,
        monto: double.parse(j['monto'].toString()),
        metodoPago: MetodoPago.fromValue(j['metodo_pago'] as String),
        estado: EstadoPago.fromValue(j['estado'] as String),
        fechaPago: j['fecha_pago'] != null
            ? DateTime.tryParse(j['fecha_pago'].toString())
            : null,
        referencia: j['referencia'] as String?,
      );

  Pago copyWith({
    int? idPago,
    int? idVenta,
    double? monto,
    MetodoPago? metodoPago,
    EstadoPago? estado,
    DateTime? fechaPago,
    bool clearFechaPago = false,
    String? referencia,
    bool clearReferencia = false,
  }) {
    return Pago(
      idPago: idPago ?? this.idPago,
      idVenta: idVenta ?? this.idVenta,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
      estado: estado ?? this.estado,
      fechaPago: clearFechaPago ? null : fechaPago ?? this.fechaPago,
      referencia: clearReferencia ? null : referencia ?? this.referencia,
    );
  }
}

class PaginatedPagos {
  final int count;
  final String? next;
  final String? previous;
  final List<Pago> results;

  const PaginatedPagos({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedPagos.fromJson(Map<String, dynamic> j) => PaginatedPagos(
        count: j['count'] as int,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) => Pago.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
