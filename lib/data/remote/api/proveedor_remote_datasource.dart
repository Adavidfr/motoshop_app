import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../remote/api/dio_client.dart';
import '../dto/paginated_response_dto.dart';
import '../dto/proveedor_dto.dart';

class ProveedorRemoteDatasource {
  final Dio _dio;

  ProveedorRemoteDatasource(this._dio);


  Future<PaginatedResponseDto<ProveedorDto>> getProveedores({
    int page = 1,
    int pageSize = 10,
    String? search,
    bool? estado,
    String? nombre,
    String? contacto,
    String? correo,
    String ordering = 'nombre',
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'ordering': ordering,
      };

      if (_tieneTexto(search)) {
        queryParameters['search'] = search!.trim();
      }

      if (estado != null) {
        queryParameters['estado'] = estado;
      }

      if (_tieneTexto(nombre)) {
        queryParameters['nombre'] = nombre!.trim();
      }

      if (_tieneTexto(contacto)) {
        queryParameters['contacto'] = contacto!.trim();
      }

      if (_tieneTexto(correo)) {
        queryParameters['correo'] = correo!.trim();
      }

      final response = await _dio.get(
        '/proveedores/',
        queryParameters: queryParameters,
      );

      return PaginatedResponseDto<ProveedorDto>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        (Map<String, dynamic> json) {
          return ProveedorDto.fromJson(json);
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }


  Future<ProveedorDto> getProveedorById(int id) async {
    try {
      final response = await _dio.get('/proveedores/$id/');

      return ProveedorDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }


  Future<ProveedorDto> createProveedor(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        '/proveedores/',
        data: payload,
      );

      return ProveedorDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }


  Future<ProveedorDto> updateProveedor(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        '/proveedores/$id/',
        data: payload,
      );

      return ProveedorDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }


  Future<ProveedorDto> patchProveedor(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/proveedores/$id/',
        data: payload,
      );

      return ProveedorDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }


  Future<void> deleteProveedor(int id) async {
    try {
      await _dio.delete('/proveedores/$id/');
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }


  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/proveedores/stats/');

      return Map<String, dynamic>.from(
        response.data as Map,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  bool _tieneTexto(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}


final proveedorDatasourceProvider =
    Provider<ProveedorRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);

  return ProveedorRemoteDatasource(dio);
});