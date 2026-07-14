// lib/presentation/providers/documentos_venta_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/documento_venta_remote_datasource.dart';
import '../../domain/model/documento_venta.dart';

// ── Form states ───────────────────────────────────────────────────────────────

sealed class DocumentoVentaFormState {
  const DocumentoVentaFormState();
}

class DocumentoVentaFormIdle extends DocumentoVentaFormState {
  const DocumentoVentaFormIdle();
}

class DocumentoVentaFormSaving extends DocumentoVentaFormState {
  const DocumentoVentaFormSaving();
}

class DocumentoVentaFormSuccess extends DocumentoVentaFormState {
  final String message;
  const DocumentoVentaFormSuccess(this.message);
}

class DocumentoVentaFormError extends DocumentoVentaFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;
  const DocumentoVentaFormError(this.message, {this.fieldErrors});
  String? fieldError(String field) => fieldErrors?[field]?.toString();
}

// ── State ─────────────────────────────────────────────────────────────────────

class DocumentosVentaAdminState {
  final List<DocumentoVenta> documentos;
  final bool isLoading;
  final String? error;

  final String search;
  final String? filtroTipo;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final DocumentoVentaFormState formState;

  const DocumentosVentaAdminState({
    this.documentos = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroTipo,
    this.ordering = '-fecha_subida',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const DocumentoVentaFormIdle(),
  });

  DocumentosVentaAdminState copyWith({
    List<DocumentoVenta>? documentos,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? filtroTipo,
    bool clearFiltroTipo = false,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    DocumentoVentaFormState? formState,
  }) {
    return DocumentosVentaAdminState(
      documentos: documentos ?? this.documentos,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      filtroTipo: clearFiltroTipo ? null : filtroTipo ?? this.filtroTipo,
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

class DocumentosVentaAdminNotifier
    extends StateNotifier<DocumentosVentaAdminState> {
  final DocumentoVentaRemoteDatasource _datasource;

  DocumentosVentaAdminNotifier(this._datasource)
      : super(const DocumentosVentaAdminState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _datasource.getDocumentos(
        page: state.page,
        pageSize: state.pageSize,
        search: _texto(state.search),
        tipo: state.filtroTipo,
        ordering: state.ordering,
      );
      state = state.copyWith(
        documentos: response.results,
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

  Future<void> setFiltroTipo(String? tipo) async {
    if (tipo == null || tipo.isEmpty) {
      state = state.copyWith(clearFiltroTipo: true, page: 1);
    } else {
      state = state.copyWith(filtroTipo: tipo, page: 1);
    }
    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
      search: '',
      clearFiltroTipo: true,
      ordering: '-fecha_subida',
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

  Future<void> crearDocumento({
    required int idVenta,
    required String tipoDocumento,
    required String archivoUrl,
    DateTime? fechaSubida,
  }) async {
    state = state.copyWith(
        formState: const DocumentoVentaFormSaving(), clearError: true);
    try {
      final creado = await _datasource.createDocumento({
        'id_venta': idVenta,
        'tipo_documento': tipoDocumento,
        'archivo_url': archivoUrl.trim(),
        if (fechaSubida != null)
          'fecha_subida': fechaSubida.toIso8601String(),
      });
      state = state.copyWith(
        documentos: [creado, ...state.documentos],
        total: state.total + 1,
        formState:
            const DocumentoVentaFormSuccess('Documento creado correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: DocumentoVentaFormError(_err(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: DocumentoVentaFormError(_err(e)));
    }
  }

  Future<void> actualizarDocumento({
    required int idDocumento,
    required int idVenta,
    required String tipoDocumento,
    required String archivoUrl,
    DateTime? fechaSubida,
  }) async {
    state = state.copyWith(
        formState: const DocumentoVentaFormSaving(), clearError: true);
    try {
      final actualizado = await _datasource.updateDocumento(idDocumento, {
        'id_venta': idVenta,
        'tipo_documento': tipoDocumento,
        'archivo_url': archivoUrl.trim(),
        'fecha_subida': fechaSubida?.toIso8601String(),
      });
      state = state.copyWith(
        documentos: state.documentos.map((d) {
          return d.idDocumento == idDocumento ? actualizado : d;
        }).toList(),
        formState: const DocumentoVentaFormSuccess(
            'Documento actualizado correctamente.'),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        formState: DocumentoVentaFormError(_err(e), fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      state = state.copyWith(formState: DocumentoVentaFormError(_err(e)));
    }
  }

  Future<void> eliminarDocumento(int idDocumento) async {
    final prev = state.documentos;
    final prevTotal = state.total;
    state = state.copyWith(
      documentos:
          state.documentos.where((d) => d.idDocumento != idDocumento).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );
    try {
      await _datasource.deleteDocumento(idDocumento);
      if (state.documentos.isEmpty && state.page > 1) {
        state = state.copyWith(page: state.page - 1);
        await load();
      }
    } catch (e) {
      state = state.copyWith(
          documentos: prev, total: prevTotal, error: _err(e));
    }
  }

  void resetFormState() =>
      state = state.copyWith(formState: const DocumentoVentaFormIdle());

  void clearError() => state = state.copyWith(clearError: true);

  String? _texto(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _err(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Sesión expirada.';
      if (e.statusCode == 403) return 'Sin permisos.';
      if (e.statusCode == 404) return 'Documento no encontrado.';
      if (e.statusCode != null && e.statusCode! >= 500) {
        return 'Error del servidor.';
      }
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final documentosVentaAdminProvider = StateNotifierProvider<
    DocumentosVentaAdminNotifier, DocumentosVentaAdminState>((ref) {
  return DocumentosVentaAdminNotifier(
      ref.watch(documentoVentaDatasourceProvider));
});
