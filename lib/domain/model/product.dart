// lib/domain/model/product.dart
//
// Modelo unificado que representa tanto una Moto como un Repuesto.
// Adaptado al backend real de Motoshop.

import 'category.dart';
import '../../core/config/app_config.dart';

enum ProductType { moto, repuesto }

class Product {
  final int          id;          // id_moto o id_repuesto según tipo
  final String       name;        // modelo (moto) o nombre (repuesto)
  final double       price;       // precio (moto) o precio_venta (repuesto)
  final int          stock;
  final String?      imageUrl;
  final Category?    category;
  final ProductType  tipo;
  final String?      description; // descripcion (repuesto) o marca+cilindraje (moto)
  final bool         isActive;    // estado == 'disponible' / estado == 'activo'

  // Campos extra de moto
  final String?      marca;
  final int?         anio;
  final int?         cilindraje;
  final String?      color;

  // Campo extra de repuesto
  final String?      sku;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.tipo,
    this.imageUrl,
    this.category,
    this.description,
    this.isActive = true,
    this.marca,
    this.anio,
    this.cilindraje,
    this.color,
    this.sku,
  });

  // ── IVA 12 % (Ecuador) ────────────────────────────────────────
  double get priceWithTax => price * (1 + AppConfig.taxRate);

  bool get inStock => stock > 0;

  // El id que envía el backend en el carrito
  int?  get idMoto     => tipo == ProductType.moto     ? id : null;
  int?  get idRepuesto => tipo == ProductType.repuesto ? id : null;

  // ── Factory desde JSON de /motos/ ─────────────────────────────
  factory Product.fromMotoJson(Map<String, dynamic> json) {
    final categoriaMap = json['categoria'];
    Category? cat;
    if (categoriaMap is Map<String, dynamic>) {
      cat = Category.fromJson(categoriaMap);
    }

    final marcaMap = json['marca'];
    final marcaNombre = marcaMap is Map<String, dynamic>
        ? marcaMap['nombre'] as String?
        : null;

    final imageRaw = json['imagen'];
    final imageUrl = AppConfig.resolveImageUrl(imageRaw?.toString());

    return Product(
      id:          json['id_moto']    as int,
      name:        '${marcaNombre ?? ''} ${json['modelo'] ?? ''}'.trim(),
      price:       double.parse(json['precio'].toString()),
      stock:       json['stock']      as int? ?? 0,
      imageUrl:    imageUrl,
      category:    cat,
      tipo:        ProductType.moto,
      description: 'Cilindraje: ${json['cilindraje']} cc · Color: ${json['color']}',
      isActive:    (json['estado'] as String?)?.toLowerCase() == 'disponible',
      marca:       marcaNombre,
      anio:        json['anio']       as int?,
      cilindraje:  json['cilindraje'] as int?,
      color:       json['color']      as String?,
    );
  }

  // ── Factory desde JSON de /repuestos/ ─────────────────────────
  factory Product.fromRepuestoJson(Map<String, dynamic> json) {
    final imageRaw = json['imagen'];
    final imageUrl = AppConfig.resolveImageUrl(imageRaw?.toString());

    return Product(
      id:          json['id_repuesto']  as int,
      name:        json['nombre']       as String,
      price:       double.parse(json['precio_venta'].toString()),
      stock:       json['stock']        as int? ?? 0,
      imageUrl:    imageUrl,
      tipo:        ProductType.repuesto,
      description: json['descripcion']  as String?,
      isActive:    (json['estado'] as String?)?.toLowerCase() == 'activo',
      sku:         json['sku']          as String?,
    );
  }
}
