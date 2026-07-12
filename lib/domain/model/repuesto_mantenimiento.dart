class RepuestoMantenimiento {
  final int idRepuestoMantenimiento;
  final int mantenimientoId;
  final int repuestoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const RepuestoMantenimiento({
    required this.idRepuestoMantenimiento,
    required this.mantenimientoId,
    required this.repuestoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  RepuestoMantenimiento copyWith({
    int? idRepuestoMantenimiento,
    int? mantenimientoId,
    int? repuestoId,
    int? cantidad,
    double? precioUnitario,
    double? subtotal,
  }) {
    return RepuestoMantenimiento(
      idRepuestoMantenimiento:
          idRepuestoMantenimiento ?? this.idRepuestoMantenimiento,
      mantenimientoId:
          mantenimientoId ?? this.mantenimientoId,
      repuestoId: repuestoId ?? this.repuestoId,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario:
          precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}