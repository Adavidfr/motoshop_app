// lib/data/remote/api/documento_venta_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_exception.dart';
import '../../../domain/model/documento_venta.dart';
import 'dio_client.dart';

abstract class DocumentoVentaRemoteDatasource {
  Future<PaginatedDocumentosVenta> getDocumentos({
    int page,
    int pageSize,
    String? search,
    String? tipo,
    int? idVenta,
    String? ordering,
  });

  Future<DocumentoVenta> getDocumentoById(int id);

  Future<DocumentoVenta> createDocumento(Map<String, dynamic> payload);

  Future<DocumentoVenta> updateDocumento(int id, Map<String, dynamic> payload);

  Future<DocumentoVenta> patchDocumento(int id, Map<String, dynamic> payload);

  Future<void> deleteDocumento(int id);
}

class DocumentoVentaRemoteDatasourceImpl
    implements DocumentoVentaRemoteDatasource {
  final Dio _dio;

  DocumentoVentaRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedDocumentosVenta> getDocumentos({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? tipo,
    int? idVenta,
    String? ordering = '-fecha_subida',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (_hasText(search)) 'search': search!.trim(),
        if (_hasText(tipo)) 'tipo_documento': tipo!.trim(),
        if (idVenta != null) 'id_venta': idVenta,
        if (_hasText(ordering)) 'ordering': ordering,
      };
      final res = await _dio.get('/documentos-venta/', queryParameters: params);
      return PaginatedDocumentosVenta.fromJson(
          res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<DocumentoVenta> getDocumentoById(int id) async {
    try {
      final res = await _dio.get('/documentos-venta/$id/');
      return DocumentoVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<DocumentoVenta> createDocumento(
      Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/documentos-venta/', data: payload);
      return DocumentoVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<DocumentoVenta> updateDocumento(
      int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put('/documentos-venta/$id/', data: payload);
      return DocumentoVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<DocumentoVenta> patchDocumento(
      int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/documentos-venta/$id/', data: payload);
      return DocumentoVenta.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteDocumento(int id) async {
    try {
      await _dio.delete('/documentos-venta/$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
}

final documentoVentaDatasourceProvider =
    Provider<DocumentoVentaRemoteDatasource>((ref) {
  return DocumentoVentaRemoteDatasourceImpl(ref.watch(dioProvider));
});
