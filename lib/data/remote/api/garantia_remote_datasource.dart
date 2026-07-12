// lib/data/remote/api/garantia_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/garantia.dart';
import 'dio_client.dart';

abstract class GarantiaRemoteDatasource {
  Future<PaginatedGarantias> getGarantias({
    int page,
    int pageSize,
    String? search,
    String? estado,
    String? ordering,
  });

  Future<Garantia> getGarantiaById(int id);

  Future<Garantia> createGarantia(Map<String, dynamic> payload);

  Future<Garantia> updateGarantia(int id, Map<String, dynamic> payload);

  Future<Garantia> patchGarantia(int id, Map<String, dynamic> payload);

  Future<void> deleteGarantia(int id);

  Future<Map<String, dynamic>> getStats();
}

class GarantiaRemoteDatasourceImpl implements GarantiaRemoteDatasource {
  final Dio _dio;

  GarantiaRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedGarantias> getGarantias({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? estado,
    String? ordering = '-fecha_inicio',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (_hasText(estado)) 'estado': estado!.trim(),
        if (_hasText(ordering)) 'ordering': ordering,
      };

      final res = await _dio.get('/garantias/', queryParameters: params);
      return PaginatedGarantias.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Garantia> getGarantiaById(int id) async {
    try {
      final res = await _dio.get('/garantias/$id/');
      return Garantia.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Garantia> createGarantia(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/garantias/', data: payload);
      return Garantia.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Garantia> updateGarantia(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/garantias/$id/', data: payload);
      return Garantia.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Garantia> patchGarantia(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/garantias/$id/', data: payload);
      return Garantia.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteGarantia(int id) async {
    try {
      await _dio.delete('/garantias/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/garantias/stats/');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

final garantiaDatasourceProvider = Provider<GarantiaRemoteDatasource>((ref) {
  return GarantiaRemoteDatasourceImpl(ref.watch(dioProvider));
});
