// lib/domain/model/factura.dart

class Factura {
  final int idFactura;
  final int idVenta;
  final String numeroFactura;
  final DateTime? fechaEmision;
  final double subtotal;
  final double iva;
  final double total;

  const Factura({
    required this.idFactura,
    required this.idVenta,
    required this.numeroFactura,
    this.fechaEmision,
    required this.subtotal,
    required this.iva,
    required this.total,
  });

  factory Factura.fromJson(Map<String, dynamic> j) => Factura(
        idFactura: j['id_factura'] as int,
        idVenta: j['id_venta'] as int,
        numeroFactura: j['numero_factura']?.toString() ?? '',
        fechaEmision: j['fecha_emision'] != null
            ? DateTime.tryParse(j['fecha_emision'].toString())
            : null,
        subtotal: double.parse(j['subtotal'].toString()),
        iva: double.parse(j['iva'].toString()),
        total: double.parse(j['total'].toString()),
      );

  Factura copyWith({
    int? idFactura,
    int? idVenta,
    String? numeroFactura,
    DateTime? fechaEmision,
    bool clearFechaEmision = false,
    double? subtotal,
    double? iva,
    double? total,
  }) {
    return Factura(
      idFactura: idFactura ?? this.idFactura,
      idVenta: idVenta ?? this.idVenta,
      numeroFactura: numeroFactura ?? this.numeroFactura,
      fechaEmision:
          clearFechaEmision ? null : fechaEmision ?? this.fechaEmision,
      subtotal: subtotal ?? this.subtotal,
      iva: iva ?? this.iva,
      total: total ?? this.total,
    );
  }
}

class PaginatedFacturas {
  final int count;
  final String? next;
  final String? previous;
  final List<Factura> results;

  const PaginatedFacturas({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedFacturas.fromJson(Map<String, dynamic> j) =>
      PaginatedFacturas(
        count: j['count'] as int,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) => Factura.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
