// lib/data/remote/api/order_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../domain/model/order.dart';
import '../../../domain/model/paginated_result.dart';
import 'dio_client.dart';

abstract class OrderRemoteDatasource {
  Future<PaginatedResult<Order>> getOrders({
    int page = 1,
    String? status,
  });

  Future<Order> getOrder(int id);

  Future<Order> createOrder(int carritoId);

  Future<Order> updateStatus(int orderId, String status);
}

class OrderRemoteDatasourceImpl implements OrderRemoteDatasource {
  final Dio _dio;

  OrderRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResult<Order>> getOrders({
    int page = 1,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (status != null && status.isNotEmpty) 'estado': status,
      };
      final res = await _dio.get('/pedidos/', queryParameters: params);
      final data = res.data as Map<String, dynamic>;
      
      final resultsList = data['results'] as List<dynamic>? ?? [];
      final orders = resultsList.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();

      return PaginatedResult<Order>(
        count: data['count'] as int? ?? 0,
        next: data['next'] as String?,
        previous: data['previous'] as String?,
        results: orders,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Order> getOrder(int id) async {
    try {
      final res = await _dio.get('/pedidos/$id/');
      return Order.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Order> createOrder(int carritoId) async {
    try {
      final res = await _dio.post('/pedidos/', data: {'id_carrito': carritoId});
      return Order.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Order> updateStatus(int orderId, String status) async {
    try {
      final res = await _dio.post('/pedidos/$orderId/update-status/', data: {'estado': status});
      return Order.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final orderDatasourceProvider = Provider<OrderRemoteDatasource>((ref) {
  return OrderRemoteDatasourceImpl(ref.watch(dioProvider));
});
