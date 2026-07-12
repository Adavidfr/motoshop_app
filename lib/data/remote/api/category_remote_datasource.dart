// lib/data/remote/api/category_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/model/category.dart';
import 'dio_client.dart';

abstract class CategoryRemoteDatasource {
  Future<List<Category>> getCategories();
}

class CategoryRemoteDatasourceImpl implements CategoryRemoteDatasource {
  final Dio _dio;
  CategoryRemoteDatasourceImpl(this._dio);

  @override
  Future<List<Category>> getCategories() async {
    final response = await _dio.get(
      '/categorias-moto/',
      queryParameters: {'page_size': 100},
    );
    final data = response.data;

    List<dynamic> results;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      results = data;
    } else {
      return [];
    }

    return results
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final categoryDatasourceProvider = Provider<CategoryRemoteDatasource>((ref) {
  return CategoryRemoteDatasourceImpl(ref.watch(dioProvider));
});
