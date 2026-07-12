// lib/data/remote/api/product_remote_datasource.dart
//
// Datasource que combina /motos/ y /repuestos/ en una lista unificada de Product.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/model/product.dart';
import 'dio_client.dart';

class PaginatedResult<T> {
  final List<T> results;
  final int     count;
  final String? next;
  final String? previous;

  const PaginatedResult({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });
}

abstract class ProductRemoteDatasource {
  Future<PaginatedResult<Product>> getProducts({
    int    page      = 1,
    int    pageSize  = 12,
    String? search,
    int?   category,
    double? priceMin,
    double? priceMax,
    String? ordering,
  });

  Future<Product> getProduct(int id, {required ProductType tipo});
}

class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  final Dio _dio;
  ProductRemoteDatasourceImpl(this._dio);

  @override
  Future<PaginatedResult<Product>> getProducts({
    int     page     = 1,
    int     pageSize = 12,
    String? search,
    int?    category,
    double? priceMin,
    double? priceMax,
    String? ordering,
  }) async {
    // Calculamos cuántos pedimos de cada endpoint
    final halfSize = (pageSize / 2).ceil();

    final futures = await Future.wait([
      _fetchMotos(
        page:     page,
        pageSize: halfSize,
        search:   search,
        category: category,
        ordering: _mapOrdering(ordering, isMoto: true),
        priceMin: priceMin,
        priceMax: priceMax,
      ),
      _fetchRepuestos(
        page:     page,
        pageSize: halfSize,
        search:   search,
        ordering: _mapOrdering(ordering, isMoto: false),
        priceMin: priceMin,
        priceMax: priceMax,
      ),
    ]);

    final motoResult     = futures[0];
    final repuestoResult = futures[1];

    // Intercalamos motos y repuestos
    final combined  = <Product>[];
    final maxLen    = motoResult.results.length > repuestoResult.results.length
        ? motoResult.results.length
        : repuestoResult.results.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < motoResult.results.length)     combined.add(motoResult.results[i]);
      if (i < repuestoResult.results.length) combined.add(repuestoResult.results[i]);
    }

    final hasNextMoto     = motoResult.next != null;
    final hasNextRepuesto = repuestoResult.next != null;

    return PaginatedResult(
      results: combined,
      count:   motoResult.count + repuestoResult.count,
      next:    (hasNextMoto || hasNextRepuesto) ? 'more' : null,
    );
  }

  Future<PaginatedResult<Product>> _fetchMotos({
    required int page,
    required int pageSize,
    String? search,
    int?    category,
    String? ordering,
    double? priceMin,
    double? priceMax,
  }) async {
    final params = <String, dynamic>{
      'page':      page,
      'page_size': pageSize,
    };
    if (search   != null && search.isNotEmpty)   params['search']      = search;
    if (category != null)                         params['categoria']   = category;
    if (ordering != null && ordering.isNotEmpty)  params['ordering']    = ordering;
    if (priceMin != null) params['precio_min'] = priceMin;
    if (priceMax != null) params['precio_max'] = priceMax;

    final res  = await _dio.get('/motos/', queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    return PaginatedResult(
      results: (data['results'] as List<dynamic>)
          .map((e) => Product.fromMotoJson(e as Map<String, dynamic>))
          .toList(),
      count: data['count'] as int? ?? 0,
      next:  data['next']  as String?,
    );
  }

  Future<PaginatedResult<Product>> _fetchRepuestos({
    required int page,
    required int pageSize,
    String? search,
    String? ordering,
    double? priceMin,
    double? priceMax,
  }) async {
    final params = <String, dynamic>{
      'page':      page,
      'page_size': pageSize,
    };
    if (search   != null && search.isNotEmpty)   params['search']   = search;
    if (ordering != null && ordering.isNotEmpty)  params['ordering'] = ordering;
    if (priceMin != null) params['precio_venta_min'] = priceMin;
    if (priceMax != null) params['precio_venta_max'] = priceMax;

    final res  = await _dio.get('/repuestos/', queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    return PaginatedResult(
      results: (data['results'] as List<dynamic>)
          .map((e) => Product.fromRepuestoJson(e as Map<String, dynamic>))
          .toList(),
      count: data['count'] as int? ?? 0,
      next:  data['next']  as String?,
    );
  }

  /// Convierte el ordering genérico del tutorial al campo real del backend.
  String? _mapOrdering(String? ordering, {required bool isMoto}) {
    if (ordering == null || ordering.isEmpty) return null;
    switch (ordering) {
      case 'price':        return isMoto ? 'precio'       : 'precio_venta';
      case '-price':       return isMoto ? '-precio'      : '-precio_venta';
      case 'name':         return isMoto ? 'modelo'       : 'nombre';
      case '-name':        return isMoto ? '-modelo'      : '-nombre';
      case '-created_at':  return isMoto ? '-fecha_registro' : '-fecha_registro';
      default:             return ordering;
    }
  }

  @override
  Future<Product> getProduct(int id, {required ProductType tipo}) async {
    if (tipo == ProductType.moto) {
      final res = await _dio.get('/motos/$id/');
      return Product.fromMotoJson(res.data as Map<String, dynamic>);
    } else {
      final res = await _dio.get('/repuestos/$id/');
      return Product.fromRepuestoJson(res.data as Map<String, dynamic>);
    }
  }
}

final productDatasourceProvider = Provider<ProductRemoteDatasource>((ref) {
  return ProductRemoteDatasourceImpl(ref.watch(dioProvider));
});
