// lib/data/remote/api/pago_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/pago.dart';
import 'dio_client.dart';

abstract class PagoRemoteDatasource {
  Future<PaginatedPagos> getPagos({
    int page,
    int pageSize,
    String? search,
    String? estado,
    String? metodoPago,
    String? ordering,
  });

  Future<Pago> getPagoById(int id);

  Future<Pago> createPago(Map<String, dynamic> payload);

  Future<Pago> updatePago(int id, Map<String, dynamic> payload);

  Future<Pago> patchPago(int id, Map<String, dynamic> payload);

  Future<void> deletePago(int id);

  Future<Map<String, dynamic>> getStats();
}

class PagoRemoteDatasourceImpl implements PagoRemoteDatasource {
  final Dio _dio;

  PagoRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedPagos> getPagos({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? estado,
    String? metodoPago,
    String? ordering = '-fecha_pago',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (_hasText(estado)) 'estado': estado!.trim(),
        if (_hasText(metodoPago)) 'metodo_pago': metodoPago!.trim(),
        if (_hasText(ordering)) 'ordering': ordering,
      };

      final res = await _dio.get('/pagos/', queryParameters: params);
      return PaginatedPagos.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Pago> getPagoById(int id) async {
    try {
      final res = await _dio.get('/pagos/$id/');
      return Pago.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Pago> createPago(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/pagos/', data: payload);
      return Pago.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Pago> updatePago(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/pagos/$id/', data: payload);
      return Pago.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Pago> patchPago(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/pagos/$id/', data: payload);
      return Pago.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deletePago(int id) async {
    try {
      await _dio.delete('/pagos/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/pagos/stats/');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

final pagoDatasourceProvider = Provider<PagoRemoteDatasource>((ref) {
  return PagoRemoteDatasourceImpl(ref.watch(dioProvider));
});
