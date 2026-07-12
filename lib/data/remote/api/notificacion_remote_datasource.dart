// lib/data/remote/api/notificacion_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/notificacion.dart';
import 'dio_client.dart';

abstract class NotificacionRemoteDatasource {
  Future<PaginatedNotificaciones> getNotificaciones({
    int page,
    int pageSize,
    String? search,
    int? idUsuario,
    bool? leido,
    String? ordering,
  });

  Future<Notificacion> getNotificacionById(int id);

  Future<Notificacion> createNotificacion(Map<String, dynamic> payload);

  Future<Notificacion> updateNotificacion(int id, Map<String, dynamic> payload);

  Future<Notificacion> patchNotificacion(int id, Map<String, dynamic> payload);

  Future<void> deleteNotificacion(int id);
}

class NotificacionRemoteDatasourceImpl implements NotificacionRemoteDatasource {
  final Dio _dio;

  NotificacionRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedNotificaciones> getNotificaciones({
    int page = 1,
    int pageSize = 10,
    String? search,
    int? idUsuario,
    bool? leido,
    String? ordering = '-fecha_creacion',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (idUsuario != null) 'id_usuario': idUsuario,
        if (leido != null) 'leido': leido,
        if (_hasText(ordering)) 'ordering': ordering,
      };
      final res = await _dio.get('/notificaciones/', queryParameters: params);
      return PaginatedNotificaciones.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Notificacion> getNotificacionById(int id) async {
    try {
      final res = await _dio.get('/notificaciones/$id/');
      return Notificacion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Notificacion> createNotificacion(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/notificaciones/', data: payload);
      return Notificacion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Notificacion> updateNotificacion(
      int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/notificaciones/$id/', data: payload);
      return Notificacion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Notificacion> patchNotificacion(
      int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/notificaciones/$id/', data: payload);
      return Notificacion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteNotificacion(int id) async {
    try {
      await _dio.delete('/notificaciones/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

final notificacionDatasourceProvider =
    Provider<NotificacionRemoteDatasource>((ref) {
  return NotificacionRemoteDatasourceImpl(ref.watch(dioProvider));
});
