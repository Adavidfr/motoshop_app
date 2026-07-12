import '../../../domain/model/proveedor.dart';

class ProveedorDto {
  final int id;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final bool estado;

  const ProveedorDto({
    required this.id,
    required this.nombre,
    this.contacto,
    this.telefono,
    this.correo,
    this.direccion,
    required this.estado,
  });

  factory ProveedorDto.fromJson(Map<String, dynamic> json) {
    return ProveedorDto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      contacto: json['contacto'] as String?,
      telefono: json['telefono'] as String?,
      correo: json['correo'] as String?,
      direccion: json['direccion'] as String?,
      estado: json['estado'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'contacto': contacto,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'estado': estado,
    };
  }

  Proveedor toDomain() {
    return Proveedor(
      id: id,
      nombre: nombre,
      contacto: contacto,
      telefono: telefono,
      correo: correo,
      direccion: direccion,
      estado: estado,
    );
  }

  factory ProveedorDto.fromDomain(Proveedor proveedor) {
    return ProveedorDto(
      id: proveedor.id,
      nombre: proveedor.nombre,
      contacto: proveedor.contacto,
      telefono: proveedor.telefono,
      correo: proveedor.correo,
      direccion: proveedor.direccion,
      estado: proveedor.estado,
    );
  }
}