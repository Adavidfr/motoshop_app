// lib/data/remote/api/factura_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/factura.dart';
import 'dio_client.dart';

abstract class FacturaRemoteDatasource {
  Future<PaginatedFacturas> getFacturas({
    int page,
    int pageSize,
    String? search,
    String? ordering,
  });

  Future<Factura> getFacturaById(int id);

  Future<Factura> createFactura(Map<String, dynamic> payload);

  Future<Factura> updateFactura(int id, Map<String, dynamic> payload);

  Future<Factura> patchFactura(int id, Map<String, dynamic> payload);

  Future<void> deleteFactura(int id);

  Future<Map<String, dynamic>> getStats();
}

class FacturaRemoteDatasourceImpl implements FacturaRemoteDatasource {
  final Dio _dio;

  FacturaRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedFacturas> getFacturas({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? ordering = '-fecha_emision',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (_hasText(ordering)) 'ordering': ordering,
      };

      final res = await _dio.get('/facturas/', queryParameters: params);
      return PaginatedFacturas.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Factura> getFacturaById(int id) async {
    try {
      final res = await _dio.get('/facturas/$id/');
      return Factura.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Factura> createFactura(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/facturas/', data: payload);
      return Factura.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Factura> updateFactura(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/facturas/$id/', data: payload);
      return Factura.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Factura> patchFactura(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/facturas/$id/', data: payload);
      return Factura.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteFactura(int id) async {
    try {
      await _dio.delete('/facturas/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/facturas/stats/');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

final facturaDatasourceProvider = Provider<FacturaRemoteDatasource>((ref) {
  return FacturaRemoteDatasourceImpl(ref.watch(dioProvider));
});
