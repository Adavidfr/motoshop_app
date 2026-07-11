class Proveedor {
  final int id;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final bool estado;

  const Proveedor({
    required this.id,
    required this.nombre,
    this.contacto,
    this.telefono,
    this.correo,
    this.direccion,
    required this.estado,
  });

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? contacto,
    String? telefono,
    String? correo,
    String? direccion,
    bool? estado,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      contacto: contacto ?? this.contacto,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      direccion: direccion ?? this.direccion,
      estado: estado ?? this.estado,
    );
  }
}