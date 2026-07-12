// lib/data/remote/api/catalog_remote_datasource.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../domain/model/marca.dart';
import '../../../domain/model/categoria_moto.dart';
import '../../../domain/model/moto.dart';
import 'dio_client.dart';

class PaginatedMarcas {
  final int count;
  final String? next;
  final List<Marca> results;

  const PaginatedMarcas({
    required this.count,
    required this.next,
    required this.results,
  });

  factory PaginatedMarcas.fromJson(Map<String, dynamic> json) => PaginatedMarcas(
        count: json['count'] as int,
        next: json['next'] as String?,
        results: (json['results'] as List)
            .map((e) => Marca.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PaginatedCategorias {
  final int count;
  final String? next;
  final List<CategoriaMoto> results;

  const PaginatedCategorias({
    required this.count,
    required this.next,
    required this.results,
  });

  factory PaginatedCategorias.fromJson(Map<String, dynamic> json) =>
      PaginatedCategorias(
        count: json['count'] as int,
        next: json['next'] as String?,
        results: (json['results'] as List)
            .map((e) => CategoriaMoto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PaginatedMotos {
  final int count;
  final String? next;
  final List<Moto> results;

  const PaginatedMotos({
    required this.count,
    required this.next,
    required this.results,
  });

  factory PaginatedMotos.fromJson(Map<String, dynamic> json) => PaginatedMotos(
        count: json['count'] as int,
        next: json['next'] as String?,
        results: (json['results'] as List)
            .map((e) => Moto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

abstract class CatalogRemoteDatasource {
  // --- Marcas ---
  Future<PaginatedMarcas> getMarcas({String? search, String? ordering, int? limit, int? offset});
  Future<Marca> createMarca(Map<String, dynamic> payload);
  Future<Marca> updateMarca(int id, Map<String, dynamic> payload);
  Future<void> deleteMarca(int id);

  // --- Categorías ---
  Future<PaginatedCategorias> getCategorias({String? search, String? ordering, int? limit, int? offset});
  Future<CategoriaMoto> createCategoria(Map<String, dynamic> payload);
  Future<CategoriaMoto> updateCategoria(int id, Map<String, dynamic> payload);
  Future<void> deleteCategoria(int id);

  // --- Motos ---
  Future<PaginatedMotos> getMotos({String? search, String? ordering, int? limit, int? offset});
  Future<Moto> createMoto({
    required int categoriaId,
    required int marcaId,
    required String modelo,
    required int anio,
    required int cilindraje,
    required String color,
    required double precio,
    required int stock,
    required String estado,
    File? imagen,
  });
  Future<Moto> updateMoto(
    int id, {
    int? categoriaId,
    int? marcaId,
    String? modelo,
    int? anio,
    int? cilindraje,
    String? color,
    double? precio,
    int? stock,
    String? estado,
    File? imagen,
  });
  Future<void> deleteMoto(int id);
}

class CatalogRemoteDatasourceImpl implements CatalogRemoteDatasource {
  final Dio _dio;

  CatalogRemoteDatasourceImpl(this._dio);

  // --- Marcas Implementation ---
  @override
  Future<PaginatedMarcas> getMarcas({String? search, String? ordering, int? limit, int? offset}) async {
    try {
      final params = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
      final res = await _dio.get('/marcas/', queryParameters: params);
      return PaginatedMarcas.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Marca> createMarca(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/marcas/', data: payload);
      return Marca.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Marca> updateMarca(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/marcas/$id/', data: payload);
      return Marca.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteMarca(int id) async {
    try {
      await _dio.delete('/marcas/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // --- Categorías Implementation ---
  @override
  Future<PaginatedCategorias> getCategorias({String? search, String? ordering, int? limit, int? offset}) async {
    try {
      final params = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
      final res = await _dio.get('/categorias-moto/', queryParameters: params);
      return PaginatedCategorias.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CategoriaMoto> createCategoria(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/categorias-moto/', data: payload);
      return CategoriaMoto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CategoriaMoto> updateCategoria(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/categorias-moto/$id/', data: payload);
      return CategoriaMoto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteCategoria(int id) async {
    try {
      await _dio.delete('/categorias-moto/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // --- Motos Implementation ---
  @override
  Future<PaginatedMotos> getMotos({String? search, String? ordering, int? limit, int? offset}) async {
    try {
      final params = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
      final res = await _dio.get('/motos/', queryParameters: params);
      return PaginatedMotos.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Moto> createMoto({
    required int categoriaId,
    required int marcaId,
    required String modelo,
    required int anio,
    required int cilindraje,
    required String color,
    required double precio,
    required int stock,
    required String estado,
    File? imagen,
  }) async {
    try {
      final data = <String, dynamic>{
        'categoria': categoriaId,
        'marca': marcaId,
        'modelo': modelo,
        'anio': anio,
        'cilindraje': cilindraje,
        'color': color,
        'precio': precio,
        'stock': stock,
        'estado': estado,
      };

      if (imagen != null) {
        final filename = imagen.path.split(Platform.pathSeparator).last;
        data['imagen'] = await MultipartFile.fromFile(
          imagen.path,
          filename: filename,
        );
      }

      final formData = FormData.fromMap(data);
      final res = await _dio.post('/motos/', data: formData);
      return Moto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Moto> updateMoto(
    int id, {
    int? categoriaId,
    int? marcaId,
    String? modelo,
    int? anio,
    int? cilindraje,
    String? color,
    double? precio,
    int? stock,
    String? estado,
    File? imagen,
  }) async {
    try {
      final data = <String, dynamic>{
        if (categoriaId != null) 'categoria': categoriaId,
        if (marcaId != null) 'marca': marcaId,
        if (modelo != null) 'modelo': modelo,
        if (anio != null) 'anio': anio,
        if (cilindraje != null) 'cilindraje': cilindraje,
        if (color != null) 'color': color,
        if (precio != null) 'precio': precio,
        if (stock != null) 'stock': stock,
        if (estado != null) 'estado': estado,
      };

      if (imagen != null) {
        final filename = imagen.path.split(Platform.pathSeparator).last;
        data['imagen'] = await MultipartFile.fromFile(
          imagen.path,
          filename: filename,
        );
      }

      final formData = FormData.fromMap(data);
      final res = await _dio.patch('/motos/$id/', data: formData);
      return Moto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteMoto(int id) async {
    try {
      await _dio.delete('/motos/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final catalogDatasourceProvider = Provider<CatalogRemoteDatasource>((ref) {
  return CatalogRemoteDatasourceImpl(ref.watch(dioProvider));
});
