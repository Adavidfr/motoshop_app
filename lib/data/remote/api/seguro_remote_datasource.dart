// lib/data/remote/api/seguro_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/seguro.dart';
import 'dio_client.dart';

abstract class SeguroRemoteDatasource {
  Future<PaginatedSeguros> getSeguros({
    int page,
    int pageSize,
    String? search,
    String? estado,
    String? tipoCobertura,
    String? ordering,
  });

  Future<Seguro> getSeguroById(int id);

  Future<Seguro> createSeguro(Map<String, dynamic> payload);

  Future<Seguro> updateSeguro(int id, Map<String, dynamic> payload);

  Future<Seguro> patchSeguro(int id, Map<String, dynamic> payload);

  Future<void> deleteSeguro(int id);

  Future<Map<String, dynamic>> getStats();
}

class SeguroRemoteDatasourceImpl implements SeguroRemoteDatasource {
  final Dio _dio;

  SeguroRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedSeguros> getSeguros({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? estado,
    String? tipoCobertura,
    String? ordering = '-fecha_inicio',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (_hasText(estado)) 'estado': estado!.trim(),
        if (_hasText(tipoCobertura)) 'tipo_cobertura': tipoCobertura!.trim(),
        if (_hasText(ordering)) 'ordering': ordering,
      };

      final res = await _dio.get('/seguros/', queryParameters: params);
      return PaginatedSeguros.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Seguro> getSeguroById(int id) async {
    try {
      final res = await _dio.get('/seguros/$id/');
      return Seguro.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Seguro> createSeguro(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/seguros/', data: payload);
      return Seguro.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Seguro> updateSeguro(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/seguros/$id/', data: payload);
      return Seguro.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Seguro> patchSeguro(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/seguros/$id/', data: payload);
      return Seguro.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteSeguro(int id) async {
    try {
      await _dio.delete('/seguros/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/seguros/stats/');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

final seguroDatasourceProvider = Provider<SeguroRemoteDatasource>((ref) {
  return SeguroRemoteDatasourceImpl(ref.watch(dioProvider));
});
