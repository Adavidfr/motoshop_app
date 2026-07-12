// lib/domain/model/category.dart

class Category {
  final int    id;
  final String name;
  final String description;
  final bool   isActive;

  const Category({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive    = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id:          json['id_categoria'] as int,
    name:        json['nombre']       as String,
    description: (json['descripcion'] as String?) ?? '',
    isActive:    (json['estado']      as bool?)   ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id_categoria': id,
    'nombre':       name,
    'descripcion':  description,
    'estado':       isActive,
  };
}
