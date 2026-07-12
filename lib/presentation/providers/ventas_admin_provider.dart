// lib/presentation/providers/ventas_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/venta_remote_datasource.dart';
import '../../domain/model/venta.dart';

class VentasAdminState {
  final List<Venta> ventas;
  final bool        isLoading;
  final bool        isLoadingMore;
  final String?     error;
  final int         total;
  final bool        hasMore;
  final String      statusFilter;
  final int         page;

  // Stats
  final int         statTotalVentas;
  final double      statTotalIngresos;
  final bool        isLoadingStats;

  const VentasAdminState({
    this.ventas            = const [],
    this.isLoading         = false,
    this.isLoadingMore     = false,
    this.error,
    this.total             = 0,
    this.hasMore           = false,
    this.statusFilter      = '',
    this.page              = 1,
    this.statTotalVentas   = 0,
    this.statTotalIngresos = 0.0,
    this.isLoadingStats    = false,
  });

  VentasAdminState copyWith({
    List<Venta>? ventas,
    bool?        isLoading,
    bool?        isLoadingMore,
    String?      error,
    int?         total,
    bool?        hasMore,
    String?      statusFilter,
    int?         page,
    int?         statTotalVentas,
    double?      statTotalIngresos,
    bool?        isLoadingStats,
  }) => VentasAdminState(
    ventas:            ventas ?? this.ventas,
    isLoading:         isLoading ?? this.isLoading,
    isLoadingMore:     isLoadingMore ?? this.isLoadingMore,
    error:             error,
    total:             total ?? this.total,
    hasMore:           hasMore ?? this.hasMore,
    statusFilter:      statusFilter ?? this.statusFilter,
    page:              page ?? this.page,
    statTotalVentas:   statTotalVentas ?? this.statTotalVentas,
    statTotalIngresos: statTotalIngresos ?? this.statTotalIngresos,
    isLoadingStats:    isLoadingStats ?? this.isLoadingStats,
  );
}

class VentasAdminNotifier extends StateNotifier<VentasAdminState> {
  final VentaRemoteDatasource _datasource;

  VentasAdminNotifier(this._datasource) : super(const VentasAdminState()) {
    load();
    loadStats();
  }

  Future<void> load({bool reset = true}) async {
    final s    = state;
    final page = reset ? 1 : s.page;

    if (reset) {
      state = s.copyWith(isLoading: true, error: null, page: 1);
    } else {
      if (s.isLoadingMore || !s.hasMore) return;
      state = s.copyWith(isLoadingMore: true);
    }

    try {
      final result = await _datasource.getVentas(
        page:   page,
        status: s.statusFilter.isEmpty ? null : s.statusFilter,
      );
      state = state.copyWith(
        ventas:        reset ? result.results : [...state.ventas, ...result.results],
        total:         result.count,
        hasMore:       result.next != null,
        isLoading:     false,
        isLoadingMore: false,
        page:          page + 1,
        error:         null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:     false,
        isLoadingMore: false,
        error:         e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoadingStats: true);
    try {
      final stats = await _datasource.getStats();
      state = state.copyWith(
        statTotalVentas:   stats['total_ventas'] as int? ?? 0,
        statTotalIngresos: double.parse((stats['total_ingresos'] ?? 0).toString()),
        isLoadingStats:    false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingStats: false);
    }
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    load();
  }

  void loadMore() => load(reset: false);
  void refresh() {
    load();
    loadStats();
  }

  Future<void> registerVenta({required int idPedido, required double totalVenta}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _datasource.createVenta(idPedido: idPedido, totalVenta: totalVenta);
      refresh();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> registrarFinanciamiento(
    int idVenta, {
    required String entidad,
    required double monto,
    required double tasa,
    required int plazo,
    required double cuota,
    required String estado,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _datasource.addFinanciamiento(
        idVenta,
        entidadFinanciera: entidad,
        montoFinanciado: monto,
        tasaInteres: tasa,
        plazoMeses: plazo,
        cuotaMensual: cuota,
        estado: estado,
      );
      refresh();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final ventasAdminProvider =
    StateNotifierProvider<VentasAdminNotifier, VentasAdminState>((ref) {
  return VentasAdminNotifier(ref.watch(ventaDatasourceProvider));
});

// Provider del detalle de venta (admin)
final ventaAdminDetailProvider = FutureProvider.family<Venta, int>((ref, id) {
  return ref.watch(ventaDatasourceProvider).getVenta(id);
});
