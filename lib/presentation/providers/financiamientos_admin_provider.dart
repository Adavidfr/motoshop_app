// lib/presentation/providers/financiamientos_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/financiamiento_remote_datasource.dart';
import '../../domain/model/venta.dart';

class FinanciamientosAdminState {
  final List<Financiamiento> financiamientos;
  final bool                 isLoading;
  final bool                 isLoadingMore;
  final String?              error;
  final int                  total;
  final bool                 hasMore;
  final String               statusFilter;
  final String               searchQuery;
  final int                  page;

  // Stats
  final int                  statTotal;
  final double               statMontoTotal;
  final double               statMontoPromedio;
  final double               statCuotaPromedio;
  final double               statPlazoPromedio;
  final bool                 isLoadingStats;

  const FinanciamientosAdminState({
    this.financiamientos   = const [],
    this.isLoading         = false,
    this.isLoadingMore     = false,
    this.error,
    this.total             = 0,
    this.hasMore           = false,
    this.statusFilter      = '',
    this.searchQuery       = '',
    this.page              = 1,
    this.statTotal         = 0,
    this.statMontoTotal     = 0.0,
    this.statMontoPromedio  = 0.0,
    this.statCuotaPromedio  = 0.0,
    this.statPlazoPromedio  = 0.0,
    this.isLoadingStats    = false,
  });

  FinanciamientosAdminState copyWith({
    List<Financiamiento>? financiamientos,
    bool?                 isLoading,
    bool?                 isLoadingMore,
    String?               error,
    int?                  total,
    bool?                 hasMore,
    String?               statusFilter,
    String?               searchQuery,
    int?                  page,
    int?                  statTotal,
    double?               statMontoTotal,
    double?               statMontoPromedio,
    double?               statCuotaPromedio,
    double?               statPlazoPromedio,
    bool?                 isLoadingStats,
  }) => FinanciamientosAdminState(
    financiamientos:   financiamientos ?? this.financiamientos,
    isLoading:         isLoading ?? this.isLoading,
    isLoadingMore:     isLoadingMore ?? this.isLoadingMore,
    error:             error,
    total:             total ?? this.total,
    hasMore:           hasMore ?? this.hasMore,
    statusFilter:      statusFilter ?? this.statusFilter,
    searchQuery:       searchQuery ?? this.searchQuery,
    page:              page ?? this.page,
    statTotal:         statTotal ?? this.statTotal,
    statMontoTotal:    statMontoTotal ?? this.statMontoTotal,
    statMontoPromedio: statMontoPromedio ?? this.statMontoPromedio,
    statCuotaPromedio: statCuotaPromedio ?? this.statCuotaPromedio,
    statPlazoPromedio: statPlazoPromedio ?? this.statPlazoPromedio,
    isLoadingStats:    isLoadingStats ?? this.isLoadingStats,
  );
}

class FinanciamientosAdminNotifier extends StateNotifier<FinanciamientosAdminState> {
  final FinanciamientoRemoteDatasource _datasource;

  FinanciamientosAdminNotifier(this._datasource) : super(const FinanciamientosAdminState()) {
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
      final result = await _datasource.getFinanciamientos(
        page:   page,
        status: s.statusFilter.isEmpty ? null : s.statusFilter,
        search: s.searchQuery.isEmpty ? null : s.searchQuery,
      );
      state = state.copyWith(
        financiamientos: reset ? result.results : [...state.financiamientos, ...result.results],
        total:           result.count,
        hasMore:         result.next != null,
        isLoading:       false,
        isLoadingMore:   false,
        page:            page + 1,
        error:           null,
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
        statTotal:         stats['total_financiamientos'] as int? ?? 0,
        statMontoTotal:    double.parse((stats['monto_total'] ?? 0).toString()),
        statMontoPromedio: double.parse((stats['monto_promedio'] ?? 0).toString()),
        statCuotaPromedio: double.parse((stats['cuota_promedio'] ?? 0).toString()),
        statPlazoPromedio: double.parse((stats['plazo_promedio_meses'] ?? 0).toString()),
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

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    load();
  }

  void loadMore() => load(reset: false);
  void refresh() {
    load();
    loadStats();
  }

  // Cambio optimista de estado
  Future<void> changeStatus(int id, String newStatus) async {
    final list = state.financiamientos;
    final itemIdx = list.indexWhere((f) => f.idFinanciamiento == id);
    if (itemIdx < 0) return;

    final prevItem = list[itemIdx];
    final updatedItem = Financiamiento(
      idFinanciamiento: prevItem.idFinanciamiento,
      idVenta:          prevItem.idVenta,
      entidadFinanciera:prevItem.entidadFinanciera,
      montoFinanciado:  prevItem.montoFinanciado,
      tasaInteres:      prevItem.tasaInteres,
      plazoMeses:       prevItem.plazoMeses,
      cuotaMensual:     prevItem.cuotaMensual,
      estado:           newStatus,
    );

    state = state.copyWith(
      financiamientos: list.map((f) => f.idFinanciamiento == id ? updatedItem : f).toList(),
    );

    try {
      await _datasource.updateFinanciamiento(id, estado: newStatus);
      loadStats(); // Refresh stats on change
    } catch (_) {
      // Revertir
      state = state.copyWith(
        financiamientos: list.map((f) => f.idFinanciamiento == id ? prevItem : f).toList(),
      );
    }
  }

  Future<void> registrarFinanciamiento({
    required int idVenta,
    required String entidad,
    required double monto,
    required double tasa,
    required int plazo,
    required double cuota,
    required String estado,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _datasource.createFinanciamiento(
        idVenta: idVenta,
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

  Future<void> eliminarFinanciamiento(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _datasource.deleteFinanciamiento(id);
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

final financiamientosAdminProvider =
    StateNotifierProvider<FinanciamientosAdminNotifier, FinanciamientosAdminState>((ref) {
  return FinanciamientosAdminNotifier(ref.watch(financiamientoDatasourceProvider));
});
