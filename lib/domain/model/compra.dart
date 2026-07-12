class Compra {
  final int idCompra;
  final int proveedorId;
  final int? motoId;
  final int? repuestoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final DateTime? fechaCompra;
  final String estado;

  const Compra({
    required this.idCompra,
    required this.proveedorId,
    this.motoId,
    this.repuestoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.fechaCompra,
    required this.estado,
  });

  bool get esCompraMoto => motoId != null;

  bool get esCompraRepuesto => repuestoId != null;

  Compra copyWith({
    int? idCompra,
    int? proveedorId,
    int? motoId,
    bool limpiarMoto = false,
    int? repuestoId,
    bool limpiarRepuesto = false,
    int? cantidad,
    double? precioUnitario,
    double? subtotal,
    DateTime? fechaCompra,
    String? estado,
  }) {
    return Compra(
      idCompra: idCompra ?? this.idCompra,
      proveedorId: proveedorId ?? this.proveedorId,
      motoId: limpiarMoto ? null : motoId ?? this.motoId,
      repuestoId:
          limpiarRepuesto ? null : repuestoId ?? this.repuestoId,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario:
          precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      estado: estado ?? this.estado,
    );
  }
}