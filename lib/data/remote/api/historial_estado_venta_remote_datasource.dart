// lib/data/remote/api/historial_estado_venta_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/historial_estado_venta.dart';
import 'dio_client.dart';

abstract class HistorialEstadoVentaRemoteDatasource {
  Future<PaginatedHistorialEstadoVenta> getHistorial({
    int page,
    int pageSize,
    String? search,
    int? idVenta,
    String? ordering,
  });

  Future<HistorialEstadoVenta> getHistorialById(int id);

  Future<HistorialEstadoVenta> createHistorial(Map<String, dynamic> payload);

  Future<HistorialEstadoVenta> updateHistorial(
      int id, Map<String, dynamic> payload);

  Future<void> deleteHistorial(int id);
}

class HistorialEstadoVentaRemoteDatasourceImpl
    implements HistorialEstadoVentaRemoteDatasource {
  final Dio _dio;

  HistorialEstadoVentaRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedHistorialEstadoVenta> getHistorial({
    int page = 1,
    int pageSize = 10,
    String? search,
    int? idVenta,
    String? ordering = '-fecha_cambio',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (idVenta != null) 'id_venta': idVenta,
        if (_hasText(ordering)) 'ordering': ordering,
      };
      final res = await _dio.get(
        '/historial-estado-venta/',
        queryParameters: params,
      );
      return PaginatedHistorialEstadoVenta.fromJson(
          res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<HistorialEstadoVenta> getHistorialById(int id) async {
    try {
      final res = await _dio.get('/historial-estado-venta/$id/');
      return HistorialEstadoVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<HistorialEstadoVenta> createHistorial(
      Map<String, dynamic> payload) async {
    try {
      final res =
          await _dio.post('/historial-estado-venta/', data: payload);
      return HistorialEstadoVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<HistorialEstadoVenta> updateHistorial(
      int id, Map<String, dynamic> payload) async {
    try {
      final res =
          await _dio.put('/historial-estado-venta/$id/', data: payload);
      return HistorialEstadoVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteHistorial(int id) async {
    try {
      await _dio.delete('/historial-estado-venta/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

final historialEstadoVentaDatasourceProvider =
    Provider<HistorialEstadoVentaRemoteDatasource>((ref) {
  return HistorialEstadoVentaRemoteDatasourceImpl(ref.watch(dioProvider));
});
