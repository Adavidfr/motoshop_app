// lib/presentation/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/product_remote_datasource.dart';
import '../../data/remote/api/venta_remote_datasource.dart';
import '../../data/remote/api/user_remote_datasource.dart';
import 'catalog_providers.dart'; // Para el provider de productos
import 'ventas_admin_provider.dart'; // O donde esté el venta_remote_datasource
import 'users_admin_provider.dart'; // O donde esté el user_remote_datasource
import '../../domain/model/product.dart';

// Import providers directos de Datasources si existen
import '../../data/remote/api/dio_client.dart';

final dashboardVentaDatasourceProvider = Provider<VentaRemoteDatasource>((ref) {
  return VentaRemoteDatasourceImpl(ref.watch(dioProvider));
});

final dashboardUserDatasourceProvider = Provider<UserRemoteDatasource>((ref) {
  return UserRemoteDatasourceImpl(ref.watch(dioProvider));
});

final dashboardProductDatasourceProvider = Provider<ProductRemoteDatasource>((ref) {
  return ProductRemoteDatasourceImpl(ref.watch(dioProvider));
});

class DashboardData {
  final int totalActiveProducts;
  final int totalOrders;
  final double totalRevenue;
  final int pendingOrders;
  final Map<String, int> ordersByStatus;
  final int activeUsers;
  final int totalUsers;

  const DashboardData({
    this.totalActiveProducts = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.pendingOrders = 0,
    this.ordersByStatus = const {},
    this.activeUsers = 0,
    this.totalUsers = 0,
  });
}

sealed class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardSuccess extends DashboardState {
  final DashboardData data;
  final DateTime loadedAt;
  const DashboardSuccess(this.data, this.loadedAt);
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ProductRemoteDatasource _prodDs;
  final VentaRemoteDatasource _ventaDs;
  final UserRemoteDatasource _userDs;

  DashboardNotifier(this._prodDs, this._ventaDs, this._userDs)
      : super(const DashboardLoading()) {
    load();
  }

  Future<void> load() async {
    state = const DashboardLoading();
    try {
      final results = await Future.wait([
        _ventaDs.getStats(),
        _userDs.getStats(),
        _prodDs.getProducts(page: 1, pageSize: 2), // Solo para obtener el count
      ]);

      final ventaStats = results[0] as Map<String, dynamic>;
      final userStats = results[1] as Map<String, dynamic>;
      final productPaginated = results[2] as PaginatedResult<Product>;

      // Extraer datos de ventas
      final byStatus = (ventaStats['por_estado'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {};

      state = DashboardSuccess(
        DashboardData(
          totalActiveProducts: productPaginated.count,
          totalOrders: (ventaStats['total_ventas'] as num?)?.toInt() ?? 0,
          totalRevenue: (ventaStats['ingresos_totales'] as num?)?.toDouble() ?? 0,
          pendingOrders: byStatus['pendiente'] ?? 0,
          ordersByStatus: byStatus,
          activeUsers: (userStats['activos'] as num?)?.toInt() ?? 0,
          totalUsers: (userStats['total'] as num?)?.toInt() ?? 0,
        ),
        DateTime.now(),
      );
    } catch (e) {
      state = DashboardError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    ref.watch(dashboardProductDatasourceProvider),
    ref.watch(dashboardVentaDatasourceProvider),
    ref.watch(dashboardUserDatasourceProvider),
  );
});
