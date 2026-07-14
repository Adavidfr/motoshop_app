// lib/presentation/providers/historial_estado_venta_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/historial_estado_venta_remote_datasource.dart';
import '../../domain/model/historial_estado_venta.dart';

// ── Form states ───────────────────────────────────────────────────────────────

sealed class HistorialFormState {
  const HistorialFormState();
}

class HistorialFormIdle extends HistorialFormState {
  const HistorialFormIdle();
}

class HistorialFormSaving extends HistorialFormState {
  const HistorialFormSaving();
}

class HistorialFormSuccess extends HistorialFormState {
  final String message;
  const HistorialFormSuccess(this.message);
}

class HistorialFormError extends HistorialFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;
  const HistorialFormError(this.message, {this.fieldErrors});
  String? fieldError(String field) => fieldErrors?[field]?.toString();
}

// ── State ─────────────────────────────────────────────────────────────────────

class HistorialEstadoVentaState {
  final List<HistorialEstadoVenta> historial;
  final bool isLoading;
  final String? error;

  final String search;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final HistorialFormState formState;

  const HistorialEstadoVentaState({
    this.historial = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.ordering = '-fecha_cambio',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const HistorialFormIdle(),
  });

  HistorialEstadoVentaState copyWith({
    List<HistorialEstadoVenta>? historial,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    HistorialFormState? formState,
  }) {
    return HistorialEstadoVentaState(
      historial: historial ?? this.historial,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      ordering: ordering ?? this.ordering,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      formState: formState ?? this.formState,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HistorialEstadoVentaNotifier
    extends StateNotifier<HistorialEstadoVentaState> {
  final HistorialEstadoVentaRemoteDatasource _datasource;

  HistorialEstadoVentaNotifier(this._datasource)
      : super(const HistorialEstadoVentaState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _datasource.getHistorial(
        page: state.page,
        pageSize: state.pageSize,
        search: _texto(state.search),
        ordering: state.ordering,
      );
      state = state.copyWith(
        historial: response.results,
        total: response.count,
        hasNextPage: response.next != null,
        hasPreviousPage: response.previous != null,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _err(e));
    }
  }

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value, page: 1);
    await load();
  }

  Future<void> setOrdering(String value) async {
    state = state.copyWith(ordering: value, page: 1);
    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
        search: '', ordering: '-fecha_cambio', page: 1);
    await load();
  }

  Future<void> siguientePagina() async {
    if (state.isLoading || !state.hasNextPage) return;
    state = state.copyWith(page: state.page + 1);
    await load();
  }

  Future<void> paginaAnterior() async {
    if (state.isLoading || !state.hasPreviousPage || state.page <= 1) return;
    state = state.copyWith(page: state.page - 1);
    await load();
  }

  Future<void> registrarCambio({
    required int idVenta,
    required String estadoNuevo,
    String? estadoAnterior,
    String? observacion,
    DateTime? fechaCambio,
  }) async {
    state = state.copyWith(
        formState: const HistorialFormSaving(), clearError: true);
    try {
      final creado = await _datasource.createHistorial({
        'id_venta': idVenta,
        'estado_nuevo': estadoNuevo.trim(),
        if (estadoAnterior != null && estadoAnterior.trim().isNotEmpty)
          'estado_anterior': estadoAnterior.trim(),
        if (observacion != null && observacion.trim().isNotEmpty)
          'observacion': observacion.trim(),
        if (fechaCambio != null)
          'fecha_cambio': fechaCambio.toIso8601String(),
      });
      state = state.copyWith(
        historial: [creado, ...state.historial],
        total: state.total + 1,
        formState:
            const HistorialFormSuccess('Cambio de estado registrado.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: HistorialFormError(_err(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: HistorialFormError(_err(e)));
    }
  }

  Future<void> eliminarHistorial(int idHistorial) async {
    final prev = state.historial;
    final prevTotal = state.total;
    state = state.copyWith(
      historial: state.historial
          .where((h) => h.idHistorial != idHistorial)
          .toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );
    try {
      await _datasource.deleteHistorial(idHistorial);
      if (state.historial.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state =
          state.copyWith(historial: prev, total: prevTotal, error: _err(e));
    }
  }

  void resetFormState() =>
      state = state.copyWith(formState: const HistorialFormIdle());

  void clearError() => state = state.copyWith(clearError: true);

  String? _texto(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _err(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Sesión expirada.';
      if (e.statusCode == 403) return 'Sin permisos.';
      if (e.statusCode == 404) return 'Registro no encontrado.';
      if (e.statusCode != null && e.statusCode! >= 500) {
        return 'Error del servidor.';
      }
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final historialEstadoVentaProvider = StateNotifierProvider<
    HistorialEstadoVentaNotifier, HistorialEstadoVentaState>((ref) {
  return HistorialEstadoVentaNotifier(
      ref.watch(historialEstadoVentaDatasourceProvider));
});
