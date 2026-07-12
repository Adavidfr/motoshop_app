// lib/presentation/providers/devoluciones_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/devolucion_remote_datasource.dart';
import '../../domain/model/devolucion.dart';

// ── Form states ───────────────────────────────────────────────────────────────

sealed class DevolucionFormState {
  const DevolucionFormState();
}

class DevolucionFormIdle extends DevolucionFormState {
  const DevolucionFormIdle();
}

class DevolucionFormSaving extends DevolucionFormState {
  const DevolucionFormSaving();
}

class DevolucionFormSuccess extends DevolucionFormState {
  final String message;
  const DevolucionFormSuccess(this.message);
}

class DevolucionFormError extends DevolucionFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;
  const DevolucionFormError(this.message, {this.fieldErrors});
  String? fieldError(String field) => fieldErrors?[field]?.toString();
}

// ── State ─────────────────────────────────────────────────────────────────────

class DevolucionesAdminState {
  final List<Devolucion> devoluciones;
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

  final DevolucionFormState formState;

  const DevolucionesAdminState({
    this.devoluciones = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroEstado,
    this.ordering = '-fecha_solicitud',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const DevolucionFormIdle(),
  });

  DevolucionesAdminState copyWith({
    List<Devolucion>? devoluciones,
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
    DevolucionFormState? formState,
  }) {
    return DevolucionesAdminState(
      devoluciones: devoluciones ?? this.devoluciones,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      filtroEstado: clearFiltroEstado ? null : filtroEstado ?? this.filtroEstado,
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

class DevolucionesAdminNotifier extends StateNotifier<DevolucionesAdminState> {
  final DevolucionRemoteDatasource _datasource;

  DevolucionesAdminNotifier(this._datasource)
      : super(const DevolucionesAdminState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _datasource.getDevoluciones(
        page: state.page,
        pageSize: state.pageSize,
        search: _texto(state.search),
        estado: state.filtroEstado,
        ordering: state.ordering,
      );
      state = state.copyWith(
        devoluciones: response.results,
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

  Future<void> setFiltroEstado(String? estado) async {
    if (estado == null || estado.isEmpty) {
      state = state.copyWith(clearFiltroEstado: true, page: 1);
    } else {
      state = state.copyWith(filtroEstado: estado, page: 1);
    }
    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
      search: '',
      clearFiltroEstado: true,
      ordering: '-fecha_solicitud',
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

  Future<void> crearDevolucion({
    required int idVenta,
    required String motivo,
    required String estadoDev,
    required double montoDevolucion,
    DateTime? fechaSolicitud,
    DateTime? fechaResolucion,
  }) async {
    state =
        state.copyWith(formState: const DevolucionFormSaving(), clearError: true);
    try {
      final creado = await _datasource.createDevolucion({
        'id_venta': idVenta,
        'motivo': motivo.trim(),
        'estado': estadoDev,
        'monto_devolucion': montoDevolucion.toStringAsFixed(2),
        if (fechaSolicitud != null)
          'fecha_solicitud': fechaSolicitud.toIso8601String(),
        if (fechaResolucion != null)
          'fecha_resolucion': fechaResolucion.toIso8601String(),
      });
      state = state.copyWith(
        devoluciones: [creado, ...state.devoluciones],
        total: state.total + 1,
        formState: const DevolucionFormSuccess('Devolución creada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: DevolucionFormError(_err(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: DevolucionFormError(_err(e)));
    }
  }

  Future<void> actualizarDevolucion({
    required int idDevolucion,
    required int idVenta,
    required String motivo,
    required String estadoDev,
    required double montoDevolucion,
    DateTime? fechaSolicitud,
    DateTime? fechaResolucion,
  }) async {
    state =
        state.copyWith(formState: const DevolucionFormSaving(), clearError: true);
    try {
      final actualizado = await _datasource.updateDevolucion(idDevolucion, {
        'id_venta': idVenta,
        'motivo': motivo.trim(),
        'estado': estadoDev,
        'monto_devolucion': montoDevolucion.toStringAsFixed(2),
        'fecha_solicitud': fechaSolicitud?.toIso8601String(),
        'fecha_resolucion': fechaResolucion?.toIso8601String(),
      });
      state = state.copyWith(
        devoluciones: state.devoluciones.map((d) {
          return d.idDevolucion == idDevolucion ? actualizado : d;
        }).toList(),
        formState:
            const DevolucionFormSuccess('Devolución actualizada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: DevolucionFormError(_err(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: DevolucionFormError(_err(e)));
    }
  }

  Future<void> cambiarEstado(int idDevolucion, String nuevoEstado) async {
    final prev = state.devoluciones;
    final devIndex = prev.indexWhere((d) => d.idDevolucion == idDevolucion);
    if (devIndex == -1) return;

    final updatedLocal =
        prev[devIndex].copyWith(estado: EstadoDevolucion.fromValue(nuevoEstado));
    final newDevoluciones = List<Devolucion>.from(prev)..[devIndex] = updatedLocal;
    state = state.copyWith(devoluciones: newDevoluciones, clearError: true);

    try {
      final actualizado = await _datasource.patchDevolucion(idDevolucion, {
        'estado': nuevoEstado,
        if (nuevoEstado == 'Resolución')
          'fecha_resolucion': DateTime.now().toIso8601String(),
      });
      state = state.copyWith(
        devoluciones: state.devoluciones.map((d) {
          return d.idDevolucion == idDevolucion ? actualizado : d;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(devoluciones: prev, error: _err(e));
    }
  }

  Future<void> eliminarDevolucion(int idDevolucion) async {
    final prev = state.devoluciones;
    final prevTotal = state.total;
    state = state.copyWith(
      devoluciones:
          state.devoluciones.where((d) => d.idDevolucion != idDevolucion).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );
    try {
      await _datasource.deleteDevolucion(idDevolucion);
      if (state.devoluciones.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state = state.copyWith(devoluciones: prev, total: prevTotal, error: _err(e));
    }
  }

  void resetFormState() =>
      state = state.copyWith(formState: const DevolucionFormIdle());

  void clearError() => state = state.copyWith(clearError: true);

  String? _texto(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _err(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Sesión expirada.';
      if (e.statusCode == 403) return 'Sin permisos.';
      if (e.statusCode == 404) return 'Devolución no encontrada.';
      if (e.statusCode != null && e.statusCode! >= 500) {
        return 'Error del servidor.';
      }
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final devolucionesAdminProvider = StateNotifierProvider<
    DevolucionesAdminNotifier, DevolucionesAdminState>((ref) {
  return DevolucionesAdminNotifier(ref.watch(devolucionDatasourceProvider));
});
