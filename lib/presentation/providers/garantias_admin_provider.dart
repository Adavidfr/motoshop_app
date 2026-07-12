// lib/presentation/providers/garantias_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/garantia_remote_datasource.dart';
import '../../domain/model/garantia.dart';

// ── Form states ───────────────────────────────────────────────────────────────

sealed class GarantiaFormState {
  const GarantiaFormState();
}

class GarantiaFormIdle extends GarantiaFormState {
  const GarantiaFormIdle();
}

class GarantiaFormSaving extends GarantiaFormState {
  const GarantiaFormSaving();
}

class GarantiaFormSuccess extends GarantiaFormState {
  final String message;
  const GarantiaFormSuccess(this.message);
}

class GarantiaFormError extends GarantiaFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const GarantiaFormError(this.message, {this.fieldErrors});

  String? fieldError(String field) => fieldErrors?[field]?.toString();
}

// ── State ─────────────────────────────────────────────────────────────────────

class GarantiasAdminState {
  final List<Garantia> garantias;
  final bool isLoading;
  final String? error;

  final String search;
  final String? filtroEstado;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final GarantiaFormState formState;

  const GarantiasAdminState({
    this.garantias = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroEstado,
    this.ordering = '-fecha_inicio',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const GarantiaFormIdle(),
  });

  GarantiasAdminState copyWith({
    List<Garantia>? garantias,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? filtroEstado,
    bool clearFiltroEstado = false,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    GarantiaFormState? formState,
  }) {
    return GarantiasAdminState(
      garantias: garantias ?? this.garantias,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      filtroEstado: clearFiltroEstado
          ? null
          : filtroEstado ?? this.filtroEstado,
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

class GarantiasAdminNotifier extends StateNotifier<GarantiasAdminState> {
  final GarantiaRemoteDatasource _datasource;

  GarantiasAdminNotifier(this._datasource)
      : super(const GarantiasAdminState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _datasource.getGarantias(
        page: state.page,
        pageSize: state.pageSize,
        search: _textoONull(state.search),
        estado: state.filtroEstado,
        ordering: state.ordering,
      );

      state = state.copyWith(
        garantias: response.results,
        total: response.count,
        hasNextPage: response.next != null,
        hasPreviousPage: response.previous != null,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mensajeError(e));
    }
  }

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value, page: 1);
    await load();
  }

  Future<void> setFiltroEstado(String? estado) async {
    if (estado == null || estado.isEmpty) {
      state = state.copyWith(clearFiltroEstado: true, page: 1);
    } else {
      state = state.copyWith(filtroEstado: estado, page: 1);
    }
    await load();
  }

  Future<void> setOrdering(String value) async {
    state = state.copyWith(ordering: value, page: 1);
    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
      search: '',
      clearFiltroEstado: true,
      ordering: '-fecha_inicio',
      page: 1,
    );
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

  Future<void> crearGarantia({
    required int idVenta,
    required int idMoto,
    required int mesesGarantia,
    required String estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? descripcion,
  }) async {
    state = state.copyWith(
      formState: const GarantiaFormSaving(),
      clearError: true,
    );

    if (mesesGarantia <= 0) {
      state = state.copyWith(
        formState: const GarantiaFormError(
          'Los meses de garantía deben ser mayor que cero.',
          fieldErrors: {
            'meses_garantia': 'Debe ser mayor que cero.',
          },
        ),
      );
      return;
    }

    try {
      final creada = await _datasource.createGarantia({
        'id_venta': idVenta,
        'id_moto': idMoto,
        'meses_garantia': mesesGarantia,
        'estado': estado,
        if (fechaInicio != null)
          'fecha_inicio': _formatDate(fechaInicio),
        if (fechaFin != null) 'fecha_fin': _formatDate(fechaFin),
        if (descripcion != null && descripcion.trim().isNotEmpty)
          'descripcion': descripcion.trim(),
      });

      state = state.copyWith(
        garantias: [creada, ...state.garantias],
        total: state.total + 1,
        formState:
            const GarantiaFormSuccess('Garantía registrada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState:
            GarantiaFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(
        formState: GarantiaFormError(_mensajeError(e)),
      );
    }
  }

  Future<void> actualizarGarantia({
    required int idGarantia,
    required int idVenta,
    required int idMoto,
    required int mesesGarantia,
    required String estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? descripcion,
  }) async {
    state = state.copyWith(
      formState: const GarantiaFormSaving(),
      clearError: true,
    );

    try {
      final actualizada = await _datasource.updateGarantia(idGarantia, {
        'id_venta': idVenta,
        'id_moto': idMoto,
        'meses_garantia': mesesGarantia,
        'estado': estado,
        'fecha_inicio': fechaInicio != null ? _formatDate(fechaInicio) : null,
        'fecha_fin': fechaFin != null ? _formatDate(fechaFin) : null,
        'descripcion': descripcion?.trim() ?? '',
      });

      state = state.copyWith(
        garantias: state.garantias.map((g) {
          return g.idGarantia == idGarantia ? actualizada : g;
        }).toList(),
        formState:
            const GarantiaFormSuccess('Garantía actualizada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState:
            GarantiaFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(
        formState: GarantiaFormError(_mensajeError(e)),
      );
    }
  }

  Future<void> cambiarEstado(int idGarantia, String nuevoEstado) async {
    final anteriores = state.garantias;

    state = state.copyWith(
      garantias: state.garantias.map((g) {
        return g.idGarantia == idGarantia
            ? g.copyWith(estado: EstadoGarantia.fromValue(nuevoEstado))
            : g;
      }).toList(),
      clearError: true,
    );

    try {
      final actualizada = await _datasource.patchGarantia(
        idGarantia,
        {'estado': nuevoEstado},
      );

      state = state.copyWith(
        garantias: state.garantias.map((g) {
          return g.idGarantia == idGarantia ? actualizada : g;
        }).toList(),
      );

      if (state.filtroEstado != null) await load();
    } catch (e) {
      state = state.copyWith(garantias: anteriores, error: _mensajeError(e));
    }
  }

  Future<void> eliminarGarantia(int idGarantia) async {
    final anteriores = state.garantias;
    final totalAnterior = state.total;

    state = state.copyWith(
      garantias:
          state.garantias.where((g) => g.idGarantia != idGarantia).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );

    try {
      await _datasource.deleteGarantia(idGarantia);

      if (state.garantias.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state = state.copyWith(
        garantias: anteriores,
        total: totalAnterior,
        error: _mensajeError(e),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(formState: const GarantiaFormIdle());
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? _textoONull(String? value) {
    final t = value?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _mensajeError(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) {
        return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
      }
      if (e.statusCode == 403) return 'No tienes permisos de administrador.';
      if (e.statusCode == 404) return 'La garantía solicitada no existe.';
      if (e.statusCode != null && e.statusCode! >= 500) {
        return 'El servidor presentó un error. Intenta nuevamente.';
      }
      return e.message;
    }
    return e
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final garantiasAdminProvider =
    StateNotifierProvider<GarantiasAdminNotifier, GarantiasAdminState>((ref) {
  return GarantiasAdminNotifier(ref.watch(garantiaDatasourceProvider));
});
