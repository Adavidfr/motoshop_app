// lib/presentation/providers/proveedores_admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/proveedor_remote_datasource.dart';
import '../../domain/model/proveedor.dart';

class ProveedoresAdminState {
  final List<Proveedor> proveedores;
  final bool isLoading;
  final String? error;
  final String search;
  final bool? filtroEstado;
  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final ProveedorFormState formState;

  const ProveedoresAdminState({
    this.proveedores = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroEstado,
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const ProveedorFormIdle(),
  });

  ProveedoresAdminState copyWith({
    List<Proveedor>? proveedores,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    bool? filtroEstado,
    bool clearFiltroEstado = false,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    ProveedorFormState? formState,
  }) {
    return ProveedoresAdminState(
      proveedores: proveedores ?? this.proveedores,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      filtroEstado: clearFiltroEstado
          ? null
          : filtroEstado ?? this.filtroEstado,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      formState: formState ?? this.formState,
    );
  }
}

sealed class ProveedorFormState {
  const ProveedorFormState();
}

class ProveedorFormIdle extends ProveedorFormState {
  const ProveedorFormIdle();
}

class ProveedorFormSaving extends ProveedorFormState {
  const ProveedorFormSaving();
}

class ProveedorFormSuccess extends ProveedorFormState {
  final String message;

  const ProveedorFormSuccess(this.message);
}

class ProveedorFormError extends ProveedorFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const ProveedorFormError(
    this.message, {
    this.fieldErrors,
  });

  String? fieldError(String field) {
    return fieldErrors?[field]?.toString();
  }
}

class ProveedoresAdminNotifier
    extends StateNotifier<ProveedoresAdminState> {
  final ProveedorRemoteDatasource _datasource;

  ProveedoresAdminNotifier(this._datasource)
      : super(const ProveedoresAdminState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await _datasource.getProveedores(
        page: state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty
            ? null
            : state.search.trim(),
        estado: state.filtroEstado,
        ordering: 'nombre',
      );

      state = state.copyWith(
        proveedores: result.results
            .map((dto) => dto.toDomain())
            .toList(),
        total: result.count,
        hasNextPage: result.next != null,
        hasPreviousPage: result.previous != null,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _obtenerMensajeError(error),
      );
    }
  }

  Future<void> setSearch(String value) async {
    state = state.copyWith(
      search: value,
      page: 1,
    );

    await load();
  }

  Future<void> setFiltroEstado(bool? estado) async {
    if (estado == null) {
      state = state.copyWith(
        clearFiltroEstado: true,
        page: 1,
      );
    } else {
      state = state.copyWith(
        filtroEstado: estado,
        page: 1,
      );
    }

    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
      search: '',
      clearFiltroEstado: true,
      page: 1,
    );

    await load();
  }

  Future<void> siguientePagina() async {
    if (state.isLoading || !state.hasNextPage) {
      return;
    }

    state = state.copyWith(
      page: state.page + 1,
    );

    await load();
  }

  Future<void> paginaAnterior() async {
    if (state.isLoading ||
        !state.hasPreviousPage ||
        state.page <= 1) {
      return;
    }

    state = state.copyWith(
      page: state.page - 1,
    );

    await load();
  }

  Future<void> setPageSize(int value) async {
    if (value <= 0) {
      return;
    }

    state = state.copyWith(
      pageSize: value,
      page: 1,
    );

    await load();
  }

  Future<void> crearProveedor({
    required String nombre,
    String? contacto,
    String? telefono,
    String? correo,
    String? direccion,
    bool estado = true,
  }) async {
    state = state.copyWith(
      formState: const ProveedorFormSaving(),
      clearError: true,
    );

    try {
      final creado = await _datasource.createProveedor({
        'nombre': nombre.trim(),
        'contacto': _normalizarTexto(contacto),
        'telefono': _normalizarTexto(telefono),
        'correo': _normalizarTexto(correo),
        'direccion': _normalizarTexto(direccion),
        'estado': estado,
      });

      final proveedorCreado = creado.toDomain();

      state = state.copyWith(
        proveedores: [
          proveedorCreado,
          ...state.proveedores,
        ],
        total: state.total + 1,
        formState: const ProveedorFormSuccess(
          'Proveedor creado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: ProveedorFormError(
          error.message,
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: ProveedorFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }

  Future<void> actualizarProveedor({
    required int id,
    required String nombre,
    String? contacto,
    String? telefono,
    String? correo,
    String? direccion,
    required bool estado,
  }) async {
    state = state.copyWith(
      formState: const ProveedorFormSaving(),
      clearError: true,
    );

    try {
      final actualizado = await _datasource.updateProveedor(
        id,
        {
          'nombre': nombre.trim(),
          'contacto': _normalizarTexto(contacto),
          'telefono': _normalizarTexto(telefono),
          'correo': _normalizarTexto(correo),
          'direccion': _normalizarTexto(direccion),
          'estado': estado,
        },
      );

      final proveedorActualizado = actualizado.toDomain();

      state = state.copyWith(
        proveedores: state.proveedores.map((proveedor) {
          return proveedor.id == id
              ? proveedorActualizado
              : proveedor;
        }).toList(),
        formState: const ProveedorFormSuccess(
          'Proveedor actualizado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: ProveedorFormError(
          error.message,
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: ProveedorFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }

  Future<void> toggleEstado(
    int id,
    bool nuevoEstado,
  ) async {
    final proveedoresAnteriores = state.proveedores;

    state = state.copyWith(
      proveedores: state.proveedores.map((proveedor) {
        return proveedor.id == id
            ? proveedor.copyWith(estado: nuevoEstado)
            : proveedor;
      }).toList(),
      clearError: true,
    );

    try {
      final actualizado = await _datasource.patchProveedor(
        id,
        {
          'estado': nuevoEstado,
        },
      );

      final proveedorActualizado = actualizado.toDomain();

      state = state.copyWith(
        proveedores: state.proveedores.map((proveedor) {
          return proveedor.id == id
              ? proveedorActualizado
              : proveedor;
        }).toList(),
      );

      if (state.filtroEstado != null) {
        await load();
      }
    } catch (error) {
      state = state.copyWith(
        proveedores: proveedoresAnteriores,
        error: _obtenerMensajeError(error),
      );
    }
  }

  Future<void> eliminarProveedor(int id) async {
    final proveedoresAnteriores = state.proveedores;
    final totalAnterior = state.total;

    state = state.copyWith(
      proveedores: state.proveedores
          .where((proveedor) => proveedor.id != id)
          .toList(),
      total: state.total > 0
          ? state.total - 1
          : 0,
      clearError: true,
    );

    try {
      await _datasource.deleteProveedor(id);

      if (state.proveedores.isEmpty && state.page > 1) {
        state = state.copyWith(
          page: state.page - 1,
        );

        await load();
      }
    } catch (error) {
      state = state.copyWith(
        proveedores: proveedoresAnteriores,
        total: totalAnterior,
        error: _obtenerMensajeError(error),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(
      formState: const ProveedorFormIdle(),
    );
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  String? _normalizarTexto(String? value) {
    final texto = value?.trim();

    if (texto == null || texto.isEmpty) {
      return null;
    }

    return texto;
  }

  String _obtenerMensajeError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
      }

      if (error.statusCode == 403) {
        return 'No tienes permisos de administrador para realizar esta acción.';
      }

      if (error.statusCode == 404) {
        return 'El proveedor solicitado no existe.';
      }

      if (error.statusCode != null &&
          error.statusCode! >= 500) {
        return 'El servidor presentó un error. Intenta nuevamente.';
      }

      return error.message;
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');
  }
}

final proveedoresAdminProvider = StateNotifierProvider<
    ProveedoresAdminNotifier,
    ProveedoresAdminState>((ref) {
  return ProveedoresAdminNotifier(
    ref.watch(proveedorDatasourceProvider),
  );
});