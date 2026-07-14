// lib/presentation/providers/notificaciones_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/notificacion_remote_datasource.dart';
import '../../domain/model/notificacion.dart';

// ── Form states ───────────────────────────────────────────────────────────────

sealed class NotificacionFormState {
  const NotificacionFormState();
}

class NotificacionFormIdle extends NotificacionFormState {
  const NotificacionFormIdle();
}

class NotificacionFormSaving extends NotificacionFormState {
  const NotificacionFormSaving();
}

class NotificacionFormSuccess extends NotificacionFormState {
  final String message;
  const NotificacionFormSuccess(this.message);
}

class NotificacionFormError extends NotificacionFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;
  const NotificacionFormError(this.message, {this.fieldErrors});
  String? fieldError(String field) => fieldErrors?[field]?.toString();
}

// ── State ─────────────────────────────────────────────────────────────────────

class NotificacionesAdminState {
  final List<Notificacion> notificaciones;
  final bool isLoading;
  final String? error;

  final String search;
  final bool? filtroLeido;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final NotificacionFormState formState;

  const NotificacionesAdminState({
    this.notificaciones = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroLeido,
    this.ordering = '-fecha_creacion',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const NotificacionFormIdle(),
  });

  NotificacionesAdminState copyWith({
    List<Notificacion>? notificaciones,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    bool? filtroLeido,
    bool clearFiltroLeido = false,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    NotificacionFormState? formState,
  }) {
    return NotificacionesAdminState(
      notificaciones: notificaciones ?? this.notificaciones,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      filtroLeido: clearFiltroLeido ? null : filtroLeido ?? this.filtroLeido,
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

class NotificacionesAdminNotifier
    extends StateNotifier<NotificacionesAdminState> {
  final NotificacionRemoteDatasource _datasource;

  NotificacionesAdminNotifier(this._datasource)
      : super(const NotificacionesAdminState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _datasource.getNotificaciones(
        page: state.page,
        pageSize: state.pageSize,
        search: _texto(state.search),
        leido: state.filtroLeido,
        ordering: state.ordering,
      );
      state = state.copyWith(
        notificaciones: response.results,
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

  Future<void> setFiltroLeido(bool? leido) async {
    if (leido == null) {
      state = state.copyWith(clearFiltroLeido: true, page: 1);
    } else {
      state = state.copyWith(filtroLeido: leido, page: 1);
    }
    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
      search: '',
      clearFiltroLeido: true,
      ordering: '-fecha_creacion',
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

  Future<void> crearNotificacion({
    required int idUsuario,
    required String titulo,
    required String mensaje,
    required bool leido,
    DateTime? fechaCreacion,
  }) async {
    state = state.copyWith(
        formState: const NotificacionFormSaving(), clearError: true);
    try {
      final creado = await _datasource.createNotificacion({
        'id_usuario': idUsuario,
        'titulo': titulo.trim(),
        'mensaje': mensaje.trim(),
        'leido': leido,
        if (fechaCreacion != null)
          'fecha_creacion': fechaCreacion.toIso8601String(),
      });
      state = state.copyWith(
        notificaciones: [creado, ...state.notificaciones],
        total: state.total + 1,
        formState:
            const NotificacionFormSuccess('Notificación creada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: NotificacionFormError(_err(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: NotificacionFormError(_err(e)));
    }
  }

  Future<void> actualizarNotificacion({
    required int idNotificacion,
    required int idUsuario,
    required String titulo,
    required String mensaje,
    required bool leido,
    DateTime? fechaCreacion,
  }) async {
    state = state.copyWith(
        formState: const NotificacionFormSaving(), clearError: true);
    try {
      final actualizado = await _datasource.updateNotificacion(idNotificacion, {
        'id_usuario': idUsuario,
        'titulo': titulo.trim(),
        'mensaje': mensaje.trim(),
        'leido': leido,
        'fecha_creacion': fechaCreacion?.toIso8601String(),
      });
      state = state.copyWith(
        notificaciones: state.notificaciones.map((n) {
          return n.idNotificacion == idNotificacion ? actualizado : n;
        }).toList(),
        formState: const NotificacionFormSuccess(
            'Notificación actualizada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: NotificacionFormError(_err(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: NotificacionFormError(_err(e)));
    }
  }

  Future<void> marcarComoLeido(int idNotificacion, bool leido) async {
    final prev = state.notificaciones;
    final index = prev.indexWhere((n) => n.idNotificacion == idNotificacion);
    if (index == -1) return;

    final updatedLocal = prev[index].copyWith(leido: leido);
    final newNotifs = List<Notificacion>.from(prev)..[index] = updatedLocal;
    state = state.copyWith(notificaciones: newNotifs, clearError: true);

    try {
      final actualizado = await _datasource.patchNotificacion(idNotificacion, {
        'leido': leido,
      });
      state = state.copyWith(
        notificaciones: state.notificaciones.map((n) {
          return n.idNotificacion == idNotificacion ? actualizado : n;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(notificaciones: prev, error: _err(e));
    }
  }

  Future<void> eliminarNotificacion(int idNotificacion) async {
    final prev = state.notificaciones;
    final prevTotal = state.total;
    state = state.copyWith(
      notificaciones:
          state.notificaciones.where((n) => n.idNotificacion != idNotificacion).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );
    try {
      await _datasource.deleteNotificacion(idNotificacion);
      if (state.notificaciones.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state = state.copyWith(
          notificaciones: prev, total: prevTotal, error: _err(e));
    }
  }

  void resetFormState() =>
      state = state.copyWith(formState: const NotificacionFormIdle());

  void clearError() => state = state.copyWith(clearError: true);

  String? _texto(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _err(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Sesión expirada.';
      if (e.statusCode == 403) return 'Sin permisos.';
      if (e.statusCode == 404) return 'Notificación no encontrada.';
      if (e.statusCode != null && e.statusCode! >= 500) {
        return 'Error del servidor.';
      }
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final notificacionesAdminProvider = StateNotifierProvider<
    NotificacionesAdminNotifier, NotificacionesAdminState>((ref) {
  return NotificacionesAdminNotifier(ref.watch(notificacionDatasourceProvider));
});
