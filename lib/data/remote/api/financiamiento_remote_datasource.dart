// lib/data/remote/api/financiamiento_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../domain/model/venta.dart';
import '../../../domain/model/paginated_result.dart';
import 'dio_client.dart';

abstract class FinanciamientoRemoteDatasource {
  Future<PaginatedResult<Financiamiento>> getFinanciamientos({
    int page = 1,
    String? status,
    String? search,
  });

  Future<Financiamiento> getFinanciamiento(int id);

  Future<Financiamiento> createFinanciamiento({
    required int idVenta,
    required String entidadFinanciera,
    required double montoFinanciado,
    required double tasaInteres,
    required int plazoMeses,
    required double cuotaMensual,
    required String estado,
  });

  Future<Financiamiento> updateFinanciamiento(
    int id, {
    String? entidadFinanciera,
    double? montoFinanciado,
    double? tasaInteres,
    int? plazoMeses,
    double? cuotaMensual,
    String? estado,
  });

  Future<void> deleteFinanciamiento(int id);

  Future<Map<String, dynamic>> getStats();
}

class FinanciamientoRemoteDatasourceImpl implements FinanciamientoRemoteDatasource {
  final Dio _dio;

  FinanciamientoRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResult<Financiamiento>> getFinanciamientos({
    int page = 1,
    String? status,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (status != null && status.isNotEmpty) 'estado': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final res = await _dio.get('/financiamientos/', queryParameters: params);
      final data = res.data as Map<String, dynamic>;

      final resultsList = data['results'] as List<dynamic>? ?? [];
      final financiamientos = resultsList.map((e) => Financiamiento.fromJson(e as Map<String, dynamic>)).toList();

      return PaginatedResult<Financiamiento>(
        count: data['count'] as int? ?? 0,
        next: data['next'] as String?,
        previous: data['previous'] as String?,
        results: financiamientos,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Financiamiento> getFinanciamiento(int id) async {
    try {
      final res = await _dio.get('/financiamientos/$id/');
      return Financiamiento.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Financiamiento> createFinanciamiento({
    required int idVenta,
    required String entidadFinanciera,
    required double montoFinanciado,
    required double tasaInteres,
    required int plazoMeses,
    required double cuotaMensual,
    required String estado,
  }) async {
    try {
      final res = await _dio.post('/financiamientos/', data: {
        'id_venta': idVenta,
        'entidad_financiera': entidadFinanciera,
        'monto_financiado': montoFinanciado,
        'tasa_interes': tasaInteres,
        'plazo_meses': plazoMeses,
        'cuota_mensual': cuotaMensual,
        'estado': estado,
      });
      return Financiamiento.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Financiamiento> updateFinanciamiento(
    int id, {
    String? entidadFinanciera,
    double? montoFinanciado,
    double? tasaInteres,
    int? plazoMeses,
    double? cuotaMensual,
    String? estado,
  }) async {
    try {
      final data = <String, dynamic>{
        if (entidadFinanciera != null) 'entidad_financiera': entidadFinanciera,
        if (montoFinanciado != null) 'monto_financiado': montoFinanciado,
        if (tasaInteres != null) 'tasa_interes': tasaInteres,
        if (plazoMeses != null) 'plazo_meses': plazoMeses,
        if (cuotaMensual != null) 'cuota_mensual': cuotaMensual,
        if (estado != null) 'estado': estado,
      };
      final res = await _dio.patch('/financiamientos/$id/', data: data);
      return Financiamiento.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteFinanciamiento(int id) async {
    try {
      await _dio.delete('/financiamientos/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/financiamientos/stats/');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final financiamientoDatasourceProvider = Provider<FinanciamientoRemoteDatasource>((ref) {
  return FinanciamientoRemoteDatasourceImpl(ref.watch(dioProvider));
});
