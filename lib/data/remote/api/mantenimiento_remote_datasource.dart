import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../dto/mantenimiento_dto.dart';
import '../dto/paginated_response_dto.dart';
import 'dio_client.dart';

abstract class MantenimientoRemoteDatasource {
  Future<PaginatedResponseDto<MantenimientoDto>>
      getMantenimientos({
    int page,
    int pageSize,
    String? search,
    int? moto,
    int? usuarioCliente,
    int? servicio,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? ordering,
  });

  Future<MantenimientoDto> getMantenimientoById(
    int id,
  );

  Future<MantenimientoDto> createMantenimiento(
    Map<String, dynamic> payload,
  );

  Future<MantenimientoDto> updateMantenimiento(
    int id,
    Map<String, dynamic> payload,
  );

  Future<MantenimientoDto> patchMantenimiento(
    int id,
    Map<String, dynamic> payload,
  );

  Future<void> deleteMantenimiento(int id);

  Future<Map<String, dynamic>> getStats();
}

class MantenimientoRemoteDatasourceImpl
    implements MantenimientoRemoteDatasource {
  final Dio _dio;

  MantenimientoRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResponseDto<MantenimientoDto>>
      getMantenimientos({
    int page = 1,
    int pageSize = 10,
    String? search,
    int? moto,
    int? usuarioCliente,
    int? servicio,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? ordering = '-fecha_registro',
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_tieneTexto(search))
          'search': search!.trim(),
        if (moto != null) 'moto': moto,
        if (usuarioCliente != null)
          'usuario_cliente': usuarioCliente,
        if (servicio != null)
          'servicio': servicio,
        if (_tieneTexto(estado))
          'estado': estado!.trim(),
        if (fechaDesde != null)
          'fecha_registro_after':
              _formatDate(fechaDesde),
        if (fechaHasta != null)
          'fecha_registro_before':
              _formatDate(fechaHasta),
        if (_tieneTexto(ordering))
          'ordering': ordering,
      };

      final response = await _dio.get(
        '/mantenimientos/',
        queryParameters: queryParameters,
      );

      return PaginatedResponseDto<
          MantenimientoDto>.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        MantenimientoDto.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<MantenimientoDto> getMantenimientoById(
    int id,
  ) async {
    try {
      final response = await _dio.get(
        '/mantenimientos/$id/',
      );

      return MantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<MantenimientoDto> createMantenimiento(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        '/mantenimientos/',
        data: payload,
      );

      return MantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<MantenimientoDto> updateMantenimiento(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '/mantenimientos/$id/',
        data: payload,
      );

      return MantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<MantenimientoDto> patchMantenimiento(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/mantenimientos/$id/',
        data: payload,
      );

      return MantenimientoDto.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<void> deleteMantenimiento(
    int id,
  ) async {
    try {
      await _dio.delete(
        '/mantenimientos/$id/',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get(
        '/mantenimientos/stats/',
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
    final year = value.year
        .toString()
        .padLeft(4, '0');

    final month = value.month
        .toString()
        .padLeft(2, '0');

    final day = value.day
        .toString()
        .padLeft(2, '0');

    return '$year-$month-$day';
  }
}

final mantenimientoDatasourceProvider =
    Provider<MantenimientoRemoteDatasource>(
  (ref) {
    return MantenimientoRemoteDatasourceImpl(
      ref.watch(dioProvider),
    );
  },
);