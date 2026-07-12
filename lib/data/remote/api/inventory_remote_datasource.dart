// lib/data/remote/api/inventory_remote_datasource.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../domain/model/repuesto.dart';
import '../../../domain/model/movimiento_inventario.dart';
import 'dio_client.dart';

class PaginatedRepuestos {
  final int count;
  final String? next;
  final List<Repuesto> results;

  const PaginatedRepuestos({
    required this.count,
    required this.next,
    required this.results,
  });

  factory PaginatedRepuestos.fromJson(Map<String, dynamic> json) => PaginatedRepuestos(
        count: json['count'] as int,
        next: json['next'] as String?,
        results: (json['results'] as List)
            .map((e) => Repuesto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PaginatedMovimientos {
  final int count;
  final String? next;
  final List<MovimientoInventario> results;

  const PaginatedMovimientos({
    required this.count,
    required this.next,
    required this.results,
  });

  factory PaginatedMovimientos.fromJson(Map<String, dynamic> json) =>
      PaginatedMovimientos(
        count: json['count'] as int,
        next: json['next'] as String?,
        results: (json['results'] as List)
            .map((e) => MovimientoInventario.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

abstract class InventoryRemoteDatasource {
  // --- Repuestos ---
  Future<PaginatedRepuestos> getRepuestos({String? search, String? ordering, int? limit, int? offset});
  Future<Repuesto> createRepuesto({
    required String nombre,
    String? descripcion,
    required String sku,
    required double costo,
    required double precioVenta,
    required int stock,
    required String estado,
    File? imagen,
  });
  Future<Repuesto> updateRepuesto(
    int id, {
    String? nombre,
    String? descripcion,
    String? sku,
    double? costo,
    double? precioVenta,
    int? stock,
    String? estado,
    File? imagen,
  });
  Future<void> deleteRepuesto(int id);

  // --- Movimientos ---
  Future<PaginatedMovimientos> getMovimientos({String? search, String? ordering, int? limit, int? offset});
  Future<MovimientoInventario> createMovimiento({
    required String tipoMovimiento,
    required int cantidad,
    String? descripcion,
    int? motoId,
    int? repuestoId,
  });
}

class InventoryRemoteDatasourceImpl implements InventoryRemoteDatasource {
  final Dio _dio;

  InventoryRemoteDatasourceImpl(this._dio);

  // --- Repuestos Implementation ---
  @override
  Future<PaginatedRepuestos> getRepuestos({String? search, String? ordering, int? limit, int? offset}) async {
    try {
      final params = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
      final res = await _dio.get('/repuestos/', queryParameters: params);
      return PaginatedRepuestos.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Repuesto> createRepuesto({
    required String nombre,
    String? descripcion,
    required String sku,
    required double costo,
    required double precioVenta,
    required int stock,
    required String estado,
    File? imagen,
  }) async {
    try {
      final data = <String, dynamic>{
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'sku': sku,
        'costo': costo,
        'precio_venta': precioVenta,
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
      final res = await _dio.post('/repuestos/', data: formData);
      return Repuesto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Repuesto> updateRepuesto(
    int id, {
    String? nombre,
    String? descripcion,
    String? sku,
    double? costo,
    double? precioVenta,
    int? stock,
    String? estado,
    File? imagen,
  }) async {
    try {
      final data = <String, dynamic>{
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (sku != null) 'sku': sku,
        if (costo != null) 'costo': costo,
        if (precioVenta != null) 'precio_venta': precioVenta,
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
      final res = await _dio.patch('/repuestos/$id/', data: formData);
      return Repuesto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteRepuesto(int id) async {
    try {
      await _dio.delete('/repuestos/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // --- Movimientos Implementation ---
  @override
  Future<PaginatedMovimientos> getMovimientos({String? search, String? ordering, int? limit, int? offset}) async {
    try {
      final params = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
      final res = await _dio.get('/movimientos-inventario/', queryParameters: params);
      return PaginatedMovimientos.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<MovimientoInventario> createMovimiento({
    required String tipoMovimiento,
    required int cantidad,
    String? descripcion,
    int? motoId,
    int? repuestoId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'tipo_movimiento': tipoMovimiento,
        'cantidad': cantidad,
        if (descripcion != null) 'descripcion': descripcion,
        if (motoId != null) 'moto': motoId,
        if (repuestoId != null) 'repuesto': repuestoId,
      };
      final res = await _dio.post('/movimientos-inventario/', data: payload);
      return MovimientoInventario.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final inventoryDatasourceProvider = Provider<InventoryRemoteDatasource>((ref) {
  return InventoryRemoteDatasourceImpl(ref.watch(dioProvider));
});
