class Mantenimiento {
  final int idMantenimiento;
  final int motoId;
  final int usuarioClienteId;
  final int servicioId;
  final int kilometrajeActual;
  final String? diagnosticoInicial;
  final double costoFinal;
  final String estado;
  final DateTime? fechaRegistro;

  const Mantenimiento({
    required this.idMantenimiento,
    required this.motoId,
    required this.usuarioClienteId,
    required this.servicioId,
    required this.kilometrajeActual,
    this.diagnosticoInicial,
    required this.costoFinal,
    required this.estado,
    this.fechaRegistro,
  });

  Mantenimiento copyWith({
    int? idMantenimiento,
    int? motoId,
    int? usuarioClienteId,
    int? servicioId,
    int? kilometrajeActual,
    String? diagnosticoInicial,
    double? costoFinal,
    String? estado,
    DateTime? fechaRegistro,
  }) {
    return Mantenimiento(
      idMantenimiento:
          idMantenimiento ?? this.idMantenimiento,
      motoId: motoId ?? this.motoId,
      usuarioClienteId:
          usuarioClienteId ?? this.usuarioClienteId,
      servicioId: servicioId ?? this.servicioId,
      kilometrajeActual:
          kilometrajeActual ?? this.kilometrajeActual,
      diagnosticoInicial:
          diagnosticoInicial ?? this.diagnosticoInicial,
      costoFinal: costoFinal ?? this.costoFinal,
      estado: estado ?? this.estado,
      fechaRegistro:
          fechaRegistro ?? this.fechaRegistro,
    );
  }
}