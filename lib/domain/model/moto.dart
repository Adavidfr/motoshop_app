// lib/domain/model/moto.dart

import 'marca.dart';
import 'categoria_moto.dart';
import '../../core/config/app_config.dart';

class Moto {
  final int idMoto;
  final CategoriaMoto categoria;
  final Marca marca;
  final String modelo;
  final int anio;
  final int cilindraje;
  final String color;
  final double precio;
  final int stock;
  final String estado;
  final String? imagen;
  final String fechaRegistro;

  const Moto({
    required this.idMoto,
    required this.categoria,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.cilindraje,
    required this.color,
    required this.precio,
    required this.stock,
    required this.estado,
    this.imagen,
    required this.fechaRegistro,
  });

  factory Moto.fromJson(Map<String, dynamic> json) {
    // Handle double conversion safely (can be int or String or double in JSON)
    double parsedPrecio = 0.0;
    if (json['precio'] != null) {
      if (json['precio'] is num) {
        parsedPrecio = (json['precio'] as num).toDouble();
      } else {
        parsedPrecio = double.tryParse(json['precio'].toString()) ?? 0.0;
      }
    }

    return Moto(
      idMoto: json['id_moto'] as int,
      categoria: CategoriaMoto.fromJson(json['categoria'] as Map<String, dynamic>),
      marca: Marca.fromJson(json['marca'] as Map<String, dynamic>),
      modelo: json['modelo'] as String,
      anio: json['anio'] as int,
      cilindraje: json['cilindraje'] as int,
      color: json['color'] as String,
      precio: parsedPrecio,
      stock: json['stock'] as int,
      estado: json['estado'] as String,
      imagen: AppConfig.resolveImageUrl(json['imagen'] as String?),
      fechaRegistro: json['fecha_registro'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_moto': idMoto,
        'categoria': categoria.idCategoria,
        'marca': marca.idMarca,
        'modelo': modelo,
        'anio': anio,
        'cilindraje': cilindraje,
        'color': color,
        'precio': precio,
        'stock': stock,
        'estado': estado,
        'imagen': imagen,
        'fecha_registro': fechaRegistro,
      };

  Map<String, dynamic> toSaveJson() => {
        'categoria': categoria.idCategoria,
        'marca': marca.idMarca,
        'modelo': modelo,
        'anio': anio,
        'cilindraje': cilindraje,
        'color': color,
        'precio': precio,
        'stock': stock,
        'estado': estado,
      };

  Moto copyWith({
    int? idMoto,
    CategoriaMoto? categoria,
    Marca? marca,
    String? modelo,
    int? anio,
    int? cilindraje,
    String? color,
    double? precio,
    int? stock,
    String? estado,
    String? imagen,
    String? fechaRegistro,
  }) =>
      Moto(
        idMoto: idMoto ?? this.idMoto,
        categoria: categoria ?? this.categoria,
        marca: marca ?? this.marca,
        modelo: modelo ?? this.modelo,
        anio: anio ?? this.anio,
        cilindraje: cilindraje ?? this.cilindraje,
        color: color ?? this.color,
        precio: precio ?? this.precio,
        stock: stock ?? this.stock,
        estado: estado ?? this.estado,
        imagen: imagen ?? this.imagen,
        fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      );
}
