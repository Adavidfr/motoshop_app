import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../dto/compra_dto.dart';
import '../dto/paginated_response_dto.dart';
import 'dio_client.dart';

abstract class CompraRemoteDatasource {
  Future<PaginatedResponseDto<CompraDto>>
      getCompras({
    int page,
    int pageSize,
    String? search,
    int? proveedor,
    int? moto,
    int? repuesto,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? ordering,
  });

  Future<CompraDto> getCompraById(int id);

  Future<CompraDto> createCompra(
    Map<String, dynamic> payload,
  );

  Future<CompraDto> updateCompra(
    int id,
    Map<String, dynamic> payload,
  );

  Future<CompraDto> patchCompra(
    int id,
    Map<String, dynamic> payload,
  );

  Future<void> deleteCompra(int id);

  Future<Map<String, dynamic>> getStats();
}

class CompraRemoteDatasourceImpl
    implements CompraRemoteDatasource {
  final Dio _dio;

  CompraRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResponseDto<CompraDto>>
      getCompras({
    int page = 1,
    int pageSize = 10,
    String? search,
    int? proveedor,
    int? moto,
    int? repuesto,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? ordering = '-fecha_compra',
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_tieneTexto(search))
          'search': search!.trim(),
        if (proveedor != null)
          'proveedor': proveedor,
        if (moto != null) 'moto': moto,
        if (repuesto != null)
          'repuesto': repuesto,
        if (_tieneTexto(estado))
          'estado': estado!.trim(),
        if (fechaDesde != null)
          'fecha_compra_after':
              _formatDate(fechaDesde),
        if (fechaHasta != null)
          'fecha_compra_before':
              _formatDate(fechaHasta),
        if (_tieneTexto(ordering))
          'ordering': ordering,
      };

      final response = await _dio.get(
        '/compras/',
        queryParameters: queryParameters,
      );

      return PaginatedResponseDto<CompraDto>
          .fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        CompraDto.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<CompraDto> getCompraById(
    int id,
  ) async {
    try {
      final response = await _dio.get(
        '/compras/$id/',
      );

      return CompraDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<CompraDto> createCompra(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        '/compras/',
        data: payload,
      );

      return CompraDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<CompraDto> updateCompra(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '/compras/$id/',
        data: payload,
      );

      return CompraDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<CompraDto> patchCompra(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/compras/$id/',
        data: payload,
      );

      return CompraDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<void> deleteCompra(int id) async {
    try {
      await _dio.delete(
        '/compras/$id/',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get(
        '/compras/stats/',
      );

      return Map<String, dynamic>.from(
        response.data as Map,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  bool _tieneTexto(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString()
        .padLeft(4, '0');
    final month = value.month.toString()
        .padLeft(2, '0');
    final day = value.day.toString()
        .padLeft(2, '0');

    return '$year-$month-$day';
  }
}

final compraDatasourceProvider =
    Provider<CompraRemoteDatasource>((ref) {
  return CompraRemoteDatasourceImpl(
    ref.watch(dioProvider),
  );
});