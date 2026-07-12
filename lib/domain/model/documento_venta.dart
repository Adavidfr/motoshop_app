// lib/domain/model/documento_venta.dart

enum TipoDocumento {
  contrato('Contrato', 'Contrato'),
  factura('Factura', 'Factura'),
  garantia('Garantía', 'Garantía'),
  soat('SOAT', 'SOAT'),
  seguro('Seguro', 'Seguro'),
  otro('Otro', 'Otro');

  const TipoDocumento(this.value, this.label);
  final String value;
  final String label;

  static TipoDocumento fromValue(String v) =>
      TipoDocumento.values.firstWhere(
        (t) => t.value == v,
        orElse: () => TipoDocumento.otro,
      );
}

class DocumentoVenta {
  final int idDocumento;
  final int idVenta;
  final TipoDocumento tipoDocumento;
  final String archivoUrl;
  final DateTime? fechaSubida;

  const DocumentoVenta({
    required this.idDocumento,
    required this.idVenta,
    required this.tipoDocumento,
    required this.archivoUrl,
    this.fechaSubida,
  });

  factory DocumentoVenta.fromJson(Map<String, dynamic> j) => DocumentoVenta(
        idDocumento: j['id_documento'] as int,
        idVenta: j['id_venta'] as int,
        tipoDocumento: TipoDocumento.fromValue(
          j['tipo_documento']?.toString() ?? 'Otro',
        ),
        archivoUrl: j['archivo_url']?.toString() ?? '',
        fechaSubida: j['fecha_subida'] != null
            ? DateTime.tryParse(j['fecha_subida'].toString())
            : null,
      );

  DocumentoVenta copyWith({
    int? idDocumento,
    int? idVenta,
    TipoDocumento? tipoDocumento,
    String? archivoUrl,
    DateTime? fechaSubida,
    bool clearFechaSubida = false,
  }) {
    return DocumentoVenta(
      idDocumento: idDocumento ?? this.idDocumento,
      idVenta: idVenta ?? this.idVenta,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      archivoUrl: archivoUrl ?? this.archivoUrl,
      fechaSubida: clearFechaSubida ? null : fechaSubida ?? this.fechaSubida,
    );
  }
}

class PaginatedDocumentosVenta {
  final int count;
  final String? next;
  final String? previous;
  final List<DocumentoVenta> results;

  const PaginatedDocumentosVenta({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedDocumentosVenta.fromJson(Map<String, dynamic> j) =>
      PaginatedDocumentosVenta(
        count: j['count'] as int,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) => DocumentoVenta.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
