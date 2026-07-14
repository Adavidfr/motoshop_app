// lib/presentation/providers/facturas_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/factura_remote_datasource.dart';
import '../../domain/model/factura.dart';

// ── Form states ───────────────────────────────────────────────────────────────

sealed class FacturaFormState {
  const FacturaFormState();
}

class FacturaFormIdle extends FacturaFormState {
  const FacturaFormIdle();
}

class FacturaFormSaving extends FacturaFormState {
  const FacturaFormSaving();
}

class FacturaFormSuccess extends FacturaFormState {
  final String message;
  const FacturaFormSuccess(this.message);
}

class FacturaFormError extends FacturaFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const FacturaFormError(this.message, {this.fieldErrors});

  String? fieldError(String field) => fieldErrors?[field]?.toString();
}

// ── State ─────────────────────────────────────────────────────────────────────

class FacturasAdminState {
  final List<Factura> facturas;
  final bool isLoading;
  final String? error;

  final String search;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final FacturaFormState formState;

  const FacturasAdminState({
    this.facturas = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.ordering = '-fecha_emision',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const FacturaFormIdle(),
  });

  FacturasAdminState copyWith({
    List<Factura>? facturas,
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
    FacturaFormState? formState,
  }) {
    return FacturasAdminState(
      facturas: facturas ?? this.facturas,
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

class FacturasAdminNotifier extends StateNotifier<FacturasAdminState> {
  final FacturaRemoteDatasource _datasource;

  FacturasAdminNotifier(this._datasource)
      : super(const FacturasAdminState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _datasource.getFacturas(
        page: state.page,
        pageSize: state.pageSize,
        search: _textoONull(state.search),
        ordering: state.ordering,
      );

      state = state.copyWith(
        facturas: response.results,
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

  Future<void> setOrdering(String value) async {
    state = state.copyWith(ordering: value, page: 1);
    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
      search: '',
      ordering: '-fecha_emision',
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

  Future<void> crearFactura({
    required int idVenta,
    required String numeroFactura,
    required double subtotal,
    required double iva,
    required double total,
    DateTime? fechaEmision,
  }) async {
    state = state.copyWith(
      formState: const FacturaFormSaving(),
      clearError: true,
    );

    if (subtotal < 0 || iva < 0 || total < 0) {
      state = state.copyWith(
        formState: const FacturaFormError(
          'Los valores monetarios no pueden ser negativos.',
        ),
      );
      return;
    }

    try {
      final creada = await _datasource.createFactura({
        'id_venta': idVenta,
        'numero_factura': numeroFactura.trim(),
        'subtotal': subtotal.toStringAsFixed(2),
        'iva': iva.toStringAsFixed(2),
        'total': total.toStringAsFixed(2),
        if (fechaEmision != null)
          'fecha_emision': fechaEmision.toIso8601String(),
      });

      state = state.copyWith(
        facturas: [creada, ...state.facturas],
        total: state.total + 1,
        formState: const FacturaFormSuccess('Factura creada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState:
            FacturaFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(
        formState: FacturaFormError(_mensajeError(e)),
      );
    }
  }

  Future<void> actualizarFactura({
    required int idFactura,
    required int idVenta,
    required String numeroFactura,
    required double subtotal,
    required double iva,
    required double total,
    DateTime? fechaEmision,
  }) async {
    state = state.copyWith(
      formState: const FacturaFormSaving(),
      clearError: true,
    );

    try {
      final actualizada = await _datasource.updateFactura(idFactura, {
        'id_venta': idVenta,
        'numero_factura': numeroFactura.trim(),
        'subtotal': subtotal.toStringAsFixed(2),
        'iva': iva.toStringAsFixed(2),
        'total': total.toStringAsFixed(2),
        'fecha_emision': fechaEmision?.toIso8601String(),
      });

      state = state.copyWith(
        facturas: state.facturas.map((f) {
          return f.idFactura == idFactura ? actualizada : f;
        }).toList(),
        formState:
            const FacturaFormSuccess('Factura actualizada correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState:
            FacturaFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(
        formState: FacturaFormError(_mensajeError(e)),
      );
    }
  }

  Future<void> eliminarFactura(int idFactura) async {
    final anteriores = state.facturas;
    final totalAnterior = state.total;

    state = state.copyWith(
      facturas: state.facturas.where((f) => f.idFactura != idFactura).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );

    try {
      await _datasource.deleteFactura(idFactura);

      if (state.facturas.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state = state.copyWith(
        facturas: anteriores,
        total: totalAnterior,
        error: _mensajeError(e),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(formState: const FacturaFormIdle());
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
      if (e.statusCode == 403) return 'No tienes permisos de administrador.';
      if (e.statusCode == 404) return 'La factura solicitada no existe.';
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

final facturasAdminProvider =
    StateNotifierProvider<FacturasAdminNotifier, FacturasAdminState>((ref) {
  return FacturasAdminNotifier(ref.watch(facturaDatasourceProvider));
});
