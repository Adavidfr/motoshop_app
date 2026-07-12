import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../dto/paginated_response_dto.dart';
import '../dto/repuesto_mantenimiento_dto.dart';
import 'dio_client.dart';

abstract class RepuestoMantenimientoRemoteDatasource {
  Future<PaginatedResponseDto<RepuestoMantenimientoDto>>
      getRepuestosMantenimiento({
    int page,
    int pageSize,
    String? search,
    int? mantenimiento,
    int? repuesto,
    String? ordering,
  });

  Future<RepuestoMantenimientoDto>
      getRepuestoMantenimientoById(int id);

  Future<RepuestoMantenimientoDto>
      createRepuestoMantenimiento(
    Map<String, dynamic> payload,
  );

  Future<RepuestoMantenimientoDto>
      updateRepuestoMantenimiento(
    int id,
    Map<String, dynamic> payload,
  );

  Future<RepuestoMantenimientoDto>
      patchRepuestoMantenimiento(
    int id,
    Map<String, dynamic> payload,
  );

  Future<void> deleteRepuestoMantenimiento(int id);

  Future<Map<String, dynamic>> getStats();
}

class RepuestoMantenimientoRemoteDatasourceImpl
    implements RepuestoMantenimientoRemoteDatasource {
  final Dio _dio;

  RepuestoMantenimientoRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResponseDto<RepuestoMantenimientoDto>>
      getRepuestosMantenimiento({
    int page = 1,
    int pageSize = 10,
    String? search,
    int? mantenimiento,
    int? repuesto,
    String? ordering = 'id_repuesto_mantenimiento',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        if (mantenimiento != null)
          'mantenimiento': mantenimiento,
        if (repuesto != null) 'repuesto': repuesto,
        if (ordering != null && ordering.trim().isNotEmpty)
          'ordering': ordering,
      };

      final response = await _dio.get(
        '/repuestos-mantenimiento/',
        queryParameters: params,
      );

      return PaginatedResponseDto<
          RepuestoMantenimientoDto>.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        RepuestoMantenimientoDto.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<RepuestoMantenimientoDto>
      getRepuestoMantenimientoById(int id) async {
    try {
      final response = await _dio.get(
        '/repuestos-mantenimiento/$id/',
      );

      return RepuestoMantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<RepuestoMantenimientoDto>
      createRepuestoMantenimiento(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        '/repuestos-mantenimiento/',
        data: payload,
      );

      return RepuestoMantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<RepuestoMantenimientoDto>
      updateRepuestoMantenimiento(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '/repuestos-mantenimiento/$id/',
        data: payload,
      );

      return RepuestoMantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<RepuestoMantenimientoDto>
      patchRepuestoMantenimiento(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/repuestos-mantenimiento/$id/',
        data: payload,
      );

      return RepuestoMantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<void> deleteRepuestoMantenimiento(int id) async {
    try {
      await _dio.delete(
        '/repuestos-mantenimiento/$id/',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get(
        '/repuestos-mantenimiento/stats/',
      );

      return Map<String, dynamic>.from(
        response.data as Map,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}

final repuestoMantenimientoDatasourceProvider =
    Provider<RepuestoMantenimientoRemoteDatasource>((ref) {
  return RepuestoMantenimientoRemoteDatasourceImpl(
    ref.watch(dioProvider),
  );
});