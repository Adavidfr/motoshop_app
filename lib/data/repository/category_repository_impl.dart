// lib/data/repository/category_repository_impl.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/category.dart';
import '../remote/api/category_remote_datasource.dart';

class CategoryRepositoryImpl {
  final CategoryRemoteDatasource _datasource;
  CategoryRepositoryImpl(this._datasource);

  Future<List<Category>> getCategories() => _datasource.getCategories();
}

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryDatasourceProvider));
});
