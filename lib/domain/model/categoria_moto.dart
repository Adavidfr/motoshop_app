// lib/domain/model/categoria_moto.dart

class CategoriaMoto {
  final int idCategoria;
  final String nombre;
  final String? descripcion;
  final bool estado;

  const CategoriaMoto({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
    required this.estado,
  });

  factory CategoriaMoto.fromJson(Map<String, dynamic> json) => CategoriaMoto(
        idCategoria: json['id_categoria'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        estado: json['estado'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id_categoria': idCategoria,
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': estado,
      };

  CategoriaMoto copyWith({
    int? idCategoria,
    String? nombre,
    String? descripcion,
    bool? estado,
  }) =>
      CategoriaMoto(
        idCategoria: idCategoria ?? this.idCategoria,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        estado: estado ?? this.estado,
      );
}
