// lib/presentation/providers/pagos_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/pago_remote_datasource.dart';
import '../../domain/model/pago.dart';

// ── Estados del formulario ────────────────────────────────────────────────────

sealed class PagoFormState {
  const PagoFormState();
}

class PagoFormIdle extends PagoFormState {
  const PagoFormIdle();
}

class PagoFormSaving extends PagoFormState {
  const PagoFormSaving();
}

class PagoFormSuccess extends PagoFormState {
  final String message;
  const PagoFormSuccess(this.message);
}

class PagoFormError extends PagoFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const PagoFormError(this.message, {this.fieldErrors});

  String? fieldError(String field) =>
      fieldErrors?[field]?.toString();
}

// ── Estado principal ──────────────────────────────────────────────────────────

class PagosAdminState {
  final List<Pago> pagos;
  final bool isLoading;
  final String? error;

  final String search;
  final String? filtroEstado;
  final String? filtroMetodo;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final PagoFormState formState;

  const PagosAdminState({
    this.pagos = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroEstado,
    this.filtroMetodo,
    this.ordering = '-fecha_pago',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const PagoFormIdle(),
  });

  PagosAdminState copyWith({
    List<Pago>? pagos,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? filtroEstado,
    bool clearFiltroEstado = false,
    String? filtroMetodo,
    bool clearFiltroMetodo = false,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    PagoFormState? formState,
  }) {
    return PagosAdminState(
      pagos: pagos ?? this.pagos,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      filtroEstado: clearFiltroEstado
          ? null
          : filtroEstado ?? this.filtroEstado,
      filtroMetodo: clearFiltroMetodo
          ? null
          : filtroMetodo ?? this.filtroMetodo,
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

class PagosAdminNotifier extends StateNotifier<PagosAdminState> {
  final PagoRemoteDatasource _datasource;

  PagosAdminNotifier(this._datasource) : super(const PagosAdminState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _datasource.getPagos(
        page: state.page,
        pageSize: state.pageSize,
        search: _textoONull(state.search),
        estado: state.filtroEstado,
        metodoPago: state.filtroMetodo,
        ordering: state.ordering,
      );

      state = state.copyWith(
        pagos: response.results,
        total: response.count,
        hasNextPage: response.next != null,
        hasPreviousPage: response.previous != null,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mensajeError(e),
      );
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

  Future<void> setFiltroMetodo(String? metodo) async {
    if (metodo == null || metodo.isEmpty) {
      state = state.copyWith(clearFiltroMetodo: true, page: 1);
    } else {
      state = state.copyWith(filtroMetodo: metodo, page: 1);
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
      clearFiltroMetodo: true,
      ordering: '-fecha_pago',
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

  Future<void> crearPago({
    required int idVenta,
    required double monto,
    required String metodoPago,
    required String estado,
    DateTime? fechaPago,
    String? referencia,
  }) async {
    state = state.copyWith(
      formState: const PagoFormSaving(),
      clearError: true,
    );

    if (monto <= 0) {
      state = state.copyWith(
        formState: const PagoFormError(
          'El monto debe ser mayor que cero.',
          fieldErrors: {'monto': 'El monto debe ser mayor que cero.'},
        ),
      );
      return;
    }

    try {
      final creado = await _datasource.createPago({
        'id_venta': idVenta,
        'monto': monto.toStringAsFixed(2),
        'metodo_pago': metodoPago,
        'estado': estado,
        if (fechaPago != null) 'fecha_pago': fechaPago.toIso8601String(),
        if (referencia != null && referencia.trim().isNotEmpty)
          'referencia': referencia.trim(),
      });

      state = state.copyWith(
        pagos: [creado, ...state.pagos],
        total: state.total + 1,
        formState: const PagoFormSuccess('Pago registrado correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: PagoFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(
        formState: PagoFormError(_mensajeError(e)),
      );
    }
  }

  Future<void> actualizarPago({
    required int idPago,
    required int idVenta,
    required double monto,
    required String metodoPago,
    required String estado,
    DateTime? fechaPago,
    String? referencia,
  }) async {
    state = state.copyWith(
      formState: const PagoFormSaving(),
      clearError: true,
    );

    if (monto <= 0) {
      state = state.copyWith(
        formState: const PagoFormError(
          'El monto debe ser mayor que cero.',
        ),
      );
      return;
    }

    try {
      final actualizado = await _datasource.updatePago(idPago, {
        'id_venta': idVenta,
        'monto': monto.toStringAsFixed(2),
        'metodo_pago': metodoPago,
        'estado': estado,
        if (fechaPago != null) 'fecha_pago': fechaPago.toIso8601String(),
        'referencia': referencia?.trim() ?? '',
      });

      state = state.copyWith(
        pagos: state.pagos.map((p) {
          return p.idPago == idPago ? actualizado : p;
        }).toList(),
        formState:
            const PagoFormSuccess('Pago actualizado correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: PagoFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(
        formState: PagoFormError(_mensajeError(e)),
      );
    }
  }

  Future<void> cambiarEstado(int idPago, String nuevoEstado) async {
    final anteriores = state.pagos;

    state = state.copyWith(
      pagos: state.pagos.map((p) {
        return p.idPago == idPago
            ? p.copyWith(estado: EstadoPago.fromValue(nuevoEstado))
            : p;
      }).toList(),
      clearError: true,
    );

    try {
      final actualizado =
          await _datasource.patchPago(idPago, {'estado': nuevoEstado});

      state = state.copyWith(
        pagos: state.pagos.map((p) {
          return p.idPago == idPago ? actualizado : p;
        }).toList(),
      );

      if (state.filtroEstado != null) await load();
    } catch (e) {
      state = state.copyWith(
        pagos: anteriores,
        error: _mensajeError(e),
      );
    }
  }

  Future<void> eliminarPago(int idPago) async {
    final anteriores = state.pagos;
    final totalAnterior = state.total;

    state = state.copyWith(
      pagos: state.pagos.where((p) => p.idPago != idPago).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );

    try {
      await _datasource.deletePago(idPago);

      if (state.pagos.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state = state.copyWith(
        pagos: anteriores,
        total: totalAnterior,
        error: _mensajeError(e),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(formState: const PagoFormIdle());
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? _textoONull(String? value) {
    final t = value?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _mensajeError(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) {
        return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
      }
      if (e.statusCode == 403) {
        return 'No tienes permisos de administrador.';
      }
      if (e.statusCode == 404) {
        return 'El pago solicitado no existe.';
      }
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

final pagosAdminProvider =
    StateNotifierProvider<PagosAdminNotifier, PagosAdminState>((ref) {
  return PagosAdminNotifier(ref.watch(pagoDatasourceProvider));
});
