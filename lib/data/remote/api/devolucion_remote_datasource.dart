// lib/data/remote/api/devolucion_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/devolucion.dart';
import 'dio_client.dart';

abstract class DevolucionRemoteDatasource {
  Future<PaginatedDevoluciones> getDevoluciones({
    int page,
    int pageSize,
    String? search,
    String? estado,
    String? ordering,
  });

  Future<Devolucion> getDevolucionById(int id);

  Future<Devolucion> createDevolucion(Map<String, dynamic> payload);

  Future<Devolucion> updateDevolucion(int id, Map<String, dynamic> payload);

  Future<Devolucion> patchDevolucion(int id, Map<String, dynamic> payload);

  Future<void> deleteDevolucion(int id);

  Future<Map<String, dynamic>> getStats();
}

class DevolucionRemoteDatasourceImpl implements DevolucionRemoteDatasource {
  final Dio _dio;

  DevolucionRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedDevoluciones> getDevoluciones({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? estado,
    String? ordering = '-fecha_solicitud',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (_hasText(estado)) 'estado': estado!.trim(),
        if (_hasText(ordering)) 'ordering': ordering,
      };
      final res = await _dio.get('/devoluciones/', queryParameters: params);
      return PaginatedDevoluciones.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Devolucion> getDevolucionById(int id) async {
    try {
      final res = await _dio.get('/devoluciones/$id/');
      return Devolucion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Devolucion> createDevolucion(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/devoluciones/', data: payload);
      return Devolucion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Devolucion> updateDevolucion(
      int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/devoluciones/$id/', data: payload);
      return Devolucion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Devolucion> patchDevolucion(
      int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/devoluciones/$id/', data: payload);
      return Devolucion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteDevolucion(int id) async {
    try {
      await _dio.delete('/devoluciones/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/devoluciones/stats/');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

final devolucionDatasourceProvider =
    Provider<DevolucionRemoteDatasource>((ref) {
  return DevolucionRemoteDatasourceImpl(ref.watch(dioProvider));
});
