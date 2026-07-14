// lib/presentation/providers/seguros_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/seguro_remote_datasource.dart';
import '../../domain/model/seguro.dart';

// ── Form states ───────────────────────────────────────────────────────────────

sealed class SeguroFormState {
  const SeguroFormState();
}

class SeguroFormIdle extends SeguroFormState {
  const SeguroFormIdle();
}

class SeguroFormSaving extends SeguroFormState {
  const SeguroFormSaving();
}

class SeguroFormSuccess extends SeguroFormState {
  final String message;
  const SeguroFormSuccess(this.message);
}

class SeguroFormError extends SeguroFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const SeguroFormError(this.message, {this.fieldErrors});

  String? fieldError(String field) => fieldErrors?[field]?.toString();
}

// ── State ─────────────────────────────────────────────────────────────────────

class SegurosAdminState {
  final List<Seguro> seguros;
  final bool isLoading;
  final String? error;

  final String search;
  final String? filtroEstado;
  final String? filtroCobertura;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final SeguroFormState formState;

  const SegurosAdminState({
    this.seguros = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroEstado,
    this.filtroCobertura,
    this.ordering = '-fecha_inicio',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const SeguroFormIdle(),
  });

  SegurosAdminState copyWith({
    List<Seguro>? seguros,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? filtroEstado,
    bool clearFiltroEstado = false,
    String? filtroCobertura,
    bool clearFiltroCobertura = false,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    SeguroFormState? formState,
  }) {
    return SegurosAdminState(
      seguros: seguros ?? this.seguros,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      filtroEstado: clearFiltroEstado
          ? null
          : filtroEstado ?? this.filtroEstado,
      filtroCobertura: clearFiltroCobertura
          ? null
          : filtroCobertura ?? this.filtroCobertura,
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

class SegurosAdminNotifier extends StateNotifier<SegurosAdminState> {
  final SeguroRemoteDatasource _datasource;

  SegurosAdminNotifier(this._datasource) : super(const SegurosAdminState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _datasource.getSeguros(
        page: state.page,
        pageSize: state.pageSize,
        search: _textoONull(state.search),
        estado: state.filtroEstado,
        tipoCobertura: state.filtroCobertura,
        ordering: state.ordering,
      );

      state = state.copyWith(
        seguros: response.results,
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

  Future<void> setFiltroCobertura(String? cobertura) async {
    if (cobertura == null || cobertura.isEmpty) {
      state = state.copyWith(clearFiltroCobertura: true, page: 1);
    } else {
      state = state.copyWith(filtroCobertura: cobertura, page: 1);
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
      clearFiltroCobertura: true,
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

  Future<void> crearSeguro({
    required int idVenta,
    required String aseguradora,
    required String numeroPoliza,
    required String tipoCobertura,
    required double costoAnual,
    required String estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    state = state.copyWith(
      formState: const SeguroFormSaving(),
      clearError: true,
    );

    if (costoAnual < 0) {
      state = state.copyWith(
        formState: const SeguroFormError(
          'El costo anual no puede ser negativo.',
          fieldErrors: {'costo_anual': 'No puede ser negativo.'},
        ),
      );
      return;
    }

    try {
      final creado = await _datasource.createSeguro({
        'id_venta': idVenta,
        'aseguradora': aseguradora.trim(),
        'numero_poliza': numeroPoliza.trim(),
        'tipo_cobertura': tipoCobertura,
        'costo_anual': costoAnual.toStringAsFixed(2),
        'estado': estado,
        if (fechaInicio != null) 'fecha_inicio': _formatDate(fechaInicio),
        if (fechaFin != null) 'fecha_fin': _formatDate(fechaFin),
      });

      state = state.copyWith(
        seguros: [creado, ...state.seguros],
        total: state.total + 1,
        formState: const SeguroFormSuccess('Seguro registrado correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState:
            SeguroFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: SeguroFormError(_mensajeError(e)));
    }
  }

  Future<void> actualizarSeguro({
    required int idSeguro,
    required int idVenta,
    required String aseguradora,
    required String numeroPoliza,
    required String tipoCobertura,
    required double costoAnual,
    required String estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    state = state.copyWith(
      formState: const SeguroFormSaving(),
      clearError: true,
    );

    try {
      final actualizado = await _datasource.updateSeguro(idSeguro, {
        'id_venta': idVenta,
        'aseguradora': aseguradora.trim(),
        'numero_poliza': numeroPoliza.trim(),
        'tipo_cobertura': tipoCobertura,
        'costo_anual': costoAnual.toStringAsFixed(2),
        'estado': estado,
        'fecha_inicio': fechaInicio != null ? _formatDate(fechaInicio) : null,
        'fecha_fin': fechaFin != null ? _formatDate(fechaFin) : null,
      });

      state = state.copyWith(
        seguros: state.seguros.map((s) {
          return s.idSeguro == idSeguro ? actualizado : s;
        }).toList(),
        formState:
            const SeguroFormSuccess('Seguro actualizado correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState:
            SeguroFormError(_mensajeError(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: SeguroFormError(_mensajeError(e)));
    }
  }

  Future<void> cambiarEstado(int idSeguro, String nuevoEstado) async {
    final anteriores = state.seguros;

    state = state.copyWith(
      seguros: state.seguros.map((s) {
        return s.idSeguro == idSeguro
            ? s.copyWith(estado: EstadoSeguro.fromValue(nuevoEstado))
            : s;
      }).toList(),
      clearError: true,
    );

    try {
      final actualizado = await _datasource.patchSeguro(
        idSeguro,
        {'estado': nuevoEstado},
      );

      state = state.copyWith(
        seguros: state.seguros.map((s) {
          return s.idSeguro == idSeguro ? actualizado : s;
        }).toList(),
      );

      if (state.filtroEstado != null) await load();
    } catch (e) {
      state = state.copyWith(seguros: anteriores, error: _mensajeError(e));
    }
  }

  Future<void> eliminarSeguro(int idSeguro) async {
    final anteriores = state.seguros;
    final totalAnterior = state.total;

    state = state.copyWith(
      seguros: state.seguros.where((s) => s.idSeguro != idSeguro).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );

    try {
      await _datasource.deleteSeguro(idSeguro);

      if (state.seguros.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state = state.copyWith(
        seguros: anteriores,
        total: totalAnterior,
        error: _mensajeError(e),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(formState: const SeguroFormIdle());
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
      if (e.statusCode == 404) return 'El seguro solicitado no existe.';
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

final segurosAdminProvider =
    StateNotifierProvider<SegurosAdminNotifier, SegurosAdminState>((ref) {
  return SegurosAdminNotifier(ref.watch(seguroDatasourceProvider));
});
