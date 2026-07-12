// lib/data/remote/api/servicio_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../dto/paginated_response_dto.dart';
import '../dto/servicio_dto.dart';
import 'dio_client.dart';

abstract class ServicioRemoteDatasource {
  Future<PaginatedResponseDto<ServicioDto>> getServicios({
    int page,
    int pageSize,
    String? search,
    bool? estado,
    String? nombre,
    String? descripcion,
    double? precioBase,
    String? ordering,
  });

  Future<ServicioDto> getServicioById(int id);

  Future<ServicioDto> createServicio(
    Map<String, dynamic> payload,
  );

  Future<ServicioDto> updateServicio(
    int id,
    Map<String, dynamic> payload,
  );

  Future<ServicioDto> patchServicio(
    int id,
    Map<String, dynamic> payload,
  );

  Future<void> deleteServicio(int id);

  Future<Map<String, dynamic>> getStats();
}

class ServicioRemoteDatasourceImpl
    implements ServicioRemoteDatasource {
  final Dio _dio;

  ServicioRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResponseDto<ServicioDto>> getServicios({
    int page = 1,
    int pageSize = 10,
    String? search,
    bool? estado,
    String? nombre,
    String? descripcion,
    double? precioBase,
    String? ordering = 'nombre',
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_tieneTexto(search))
          'search': search!.trim(),
        if (estado != null)
          'estado': estado,
        if (_tieneTexto(nombre))
          'nombre': nombre!.trim(),
        if (_tieneTexto(descripcion))
          'descripcion': descripcion!.trim(),
        if (precioBase != null)
          'precio_base': precioBase,
        if (_tieneTexto(ordering))
          'ordering': ordering,
      };

      final response = await _dio.get(
        '/servicios/',
        queryParameters: queryParameters,
      );

      return PaginatedResponseDto<ServicioDto>.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        ServicioDto.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<ServicioDto> getServicioById(int id) async {
    try {
      final response = await _dio.get(
        '/servicios/$id/',
      );

      return ServicioDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<ServicioDto> createServicio(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        '/servicios/',
        data: payload,
      );

      return ServicioDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<ServicioDto> updateServicio(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '/servicios/$id/',
        data: payload,
      );

      return ServicioDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<ServicioDto> patchServicio(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/servicios/$id/',
        data: payload,
      );

      return ServicioDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<void> deleteServicio(int id) async {
    try {
      await _dio.delete(
        '/servicios/$id/',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get(
        '/servicios/stats/',
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
}

final servicioDatasourceProvider =
    Provider<ServicioRemoteDatasource>((ref) {
  return ServicioRemoteDatasourceImpl(
    ref.watch(dioProvider),
  );
});