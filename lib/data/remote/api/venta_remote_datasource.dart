// lib/data/remote/api/venta_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../domain/model/venta.dart';
import '../../../domain/model/paginated_result.dart';
import 'dio_client.dart';

abstract class VentaRemoteDatasource {
  Future<PaginatedResult<Venta>> getVentas({
    int page = 1,
    String? status,
  });

  Future<Venta> getVenta(int id);

  Future<Venta> createVenta({
    required int idPedido,
    required double totalVenta,
    String estado = 'completada',
  });

  Future<Map<String, dynamic>> getStats();

  Future<Financiamiento> addFinanciamiento(
    int idVenta, {
    required String entidadFinanciera,
    required double montoFinanciado,
    required double tasaInteres,
    required int plazoMeses,
    required double cuotaMensual,
    required String estado,
  });
}

class VentaRemoteDatasourceImpl implements VentaRemoteDatasource {
  final Dio _dio;

  VentaRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResult<Venta>> getVentas({
    int page = 1,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (status != null && status.isNotEmpty) 'estado': status,
      };
      final res = await _dio.get('/ventas/', queryParameters: params);
      final data = res.data as Map<String, dynamic>;

      final resultsList = data['results'] as List<dynamic>? ?? [];
      final ventas = resultsList.map((e) => Venta.fromJson(e as Map<String, dynamic>)).toList();

      return PaginatedResult<Venta>(
        count: data['count'] as int? ?? 0,
        next: data['next'] as String?,
        previous: data['previous'] as String?,
        results: ventas,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Venta> getVenta(int id) async {
    try {
      final res = await _dio.get('/ventas/$id/');
      return Venta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Venta> createVenta({
    required int idPedido,
    required double totalVenta,
    String estado = 'completada',
  }) async {
    try {
      final res = await _dio.post('/ventas/', data: {
        'id_pedido': idPedido,
        'total_venta': totalVenta,
        'estado': estado,
      });
      return Venta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('/ventas/stats/');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Financiamiento> addFinanciamiento(
    int idVenta, {
    required String entidadFinanciera,
    required double montoFinanciado,
    required double tasaInteres,
    required int plazoMeses,
    required double cuotaMensual,
    required String estado,
  }) async {
    try {
      final res = await _dio.post('/ventas/$idVenta/financiar/', data: {
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
}

final ventaDatasourceProvider = Provider<VentaRemoteDatasource>((ref) {
  return VentaRemoteDatasourceImpl(ref.watch(dioProvider));
});
