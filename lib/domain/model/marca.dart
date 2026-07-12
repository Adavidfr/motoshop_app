// lib/domain/model/marca.dart

class Marca {
  final int idMarca;
  final String nombre;
  final String? descripcion;
  final bool estado;

  const Marca({
    required this.idMarca,
    required this.nombre,
    this.descripcion,
    required this.estado,
  });

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        idMarca: json['id_marca'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        estado: json['estado'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id_marca': idMarca,
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': estado,
      };

  Marca copyWith({
    int? idMarca,
    String? nombre,
    String? descripcion,
    bool? estado,
  }) =>
      Marca(
        idMarca: idMarca ?? this.idMarca,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        estado: estado ?? this.estado,
      );
}
