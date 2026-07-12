import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/servicio_remote_datasource.dart';
import '../../domain/model/servicio.dart';

class ServiciosAdminState {
  final List<Servicio> servicios;
  final bool isLoading;
  final String? error;

  final String search;
  final bool? filtroEstado;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final ServicioFormState formState;

  const ServiciosAdminState({
    this.servicios = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filtroEstado,
    this.ordering = 'nombre',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const ServicioFormIdle(),
  });

  ServiciosAdminState copyWith({
    List<Servicio>? servicios,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    bool? filtroEstado,
    bool clearFiltroEstado = false,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    ServicioFormState? formState,
  }) {
    return ServiciosAdminState(
      servicios: servicios ?? this.servicios,
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
      hasPreviousPage:
          hasPreviousPage ?? this.hasPreviousPage,
      formState: formState ?? this.formState,
    );
  }
}

sealed class ServicioFormState {
  const ServicioFormState();
}

class ServicioFormIdle extends ServicioFormState {
  const ServicioFormIdle();
}

class ServicioFormSaving extends ServicioFormState {
  const ServicioFormSaving();
}

class ServicioFormSuccess extends ServicioFormState {
  final String message;

  const ServicioFormSuccess(this.message);
}

class ServicioFormError extends ServicioFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const ServicioFormError(
    this.message, {
    this.fieldErrors,
  });

  String? fieldError(String field) {
    return fieldErrors?[field]?.toString();
  }
}

class ServiciosAdminNotifier
    extends StateNotifier<ServiciosAdminState> {
  final ServicioRemoteDatasource _datasource;

  ServiciosAdminNotifier(this._datasource)
      : super(const ServiciosAdminState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await _datasource.getServicios(
        page: state.page,
        pageSize: state.pageSize,
        search: _textoONull(state.search),
        estado: state.filtroEstado,
        ordering: state.ordering,
      );

      state = state.copyWith(
        servicios: result.results
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

  Future<void> setOrdering(String value) async {
    state = state.copyWith(
      ordering: value,
      page: 1,
    );

    await load();
  }

  Future<void> limpiarFiltros() async {
    state = state.copyWith(
      search: '',
      clearFiltroEstado: true,
      ordering: 'nombre',
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

  Future<void> crearServicio({
    required String nombre,
    String? descripcion,
    required double precioBase,
    required int tiempoEstimadoMinutos,
    bool estado = true,
  }) async {
    state = state.copyWith(
      formState: const ServicioFormSaving(),
      clearError: true,
    );

    try {
      final creado = await _datasource.createServicio({
        'nombre': nombre.trim(),
        'descripcion': _textoONull(descripcion),
        'precio_base': precioBase.toStringAsFixed(2),
        'tiempo_estimado_minutos':
            tiempoEstimadoMinutos,
        'estado': estado,
      });

      final servicioCreado = creado.toDomain();

      state = state.copyWith(
        servicios: [
          servicioCreado,
          ...state.servicios,
        ],
        total: state.total + 1,
        formState: const ServicioFormSuccess(
          'Servicio creado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: ServicioFormError(
          _obtenerMensajeError(error),
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: ServicioFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }

  Future<void> actualizarServicio({
    required int id,
    required String nombre,
    String? descripcion,
    required double precioBase,
    required int tiempoEstimadoMinutos,
    required bool estado,
  }) async {
    state = state.copyWith(
      formState: const ServicioFormSaving(),
      clearError: true,
    );

    try {
      final actualizado =
          await _datasource.updateServicio(
        id,
        {
          'nombre': nombre.trim(),
          'descripcion':
              _textoONull(descripcion),
          'precio_base':
              precioBase.toStringAsFixed(2),
          'tiempo_estimado_minutos':
              tiempoEstimadoMinutos,
          'estado': estado,
        },
      );

      final servicioActualizado =
          actualizado.toDomain();

      state = state.copyWith(
        servicios: state.servicios.map((servicio) {
          return servicio.id == id
              ? servicioActualizado
              : servicio;
        }).toList(),
        formState: const ServicioFormSuccess(
          'Servicio actualizado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: ServicioFormError(
          _obtenerMensajeError(error),
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: ServicioFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }

  Future<void> toggleEstado(
    int id,
    bool nuevoEstado,
  ) async {
    final serviciosAnteriores = state.servicios;

    state = state.copyWith(
      servicios: state.servicios.map((servicio) {
        return servicio.id == id
            ? servicio.copyWith(
                estado: nuevoEstado,
              )
            : servicio;
      }).toList(),
      clearError: true,
    );

    try {
      final actualizado =
          await _datasource.patchServicio(
        id,
        {
          'estado': nuevoEstado,
        },
      );

      final servicioActualizado =
          actualizado.toDomain();

      state = state.copyWith(
        servicios: state.servicios.map((servicio) {
          return servicio.id == id
              ? servicioActualizado
              : servicio;
        }).toList(),
      );

      if (state.filtroEstado != null) {
        await load();
      }
    } catch (error) {
      state = state.copyWith(
        servicios: serviciosAnteriores,
        error: _obtenerMensajeError(error),
      );
    }
  }

  Future<void> eliminarServicio(int id) async {
    final serviciosAnteriores = state.servicios;
    final totalAnterior = state.total;

    state = state.copyWith(
      servicios: state.servicios
          .where((servicio) => servicio.id != id)
          .toList(),
      total: state.total > 0
          ? state.total - 1
          : 0,
      clearError: true,
    );

    try {
      await _datasource.deleteServicio(id);

      if (state.servicios.isEmpty &&
          state.page > 1) {
        state = state.copyWith(
          page: state.page - 1,
        );

        await load();
      }
    } catch (error) {
      state = state.copyWith(
        servicios: serviciosAnteriores,
        total: totalAnterior,
        error: _obtenerMensajeError(error),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(
      formState: const ServicioFormIdle(),
    );
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  String? _textoONull(String? value) {
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
        return 'El servicio solicitado no existe.';
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

final serviciosAdminProvider = StateNotifierProvider<
    ServiciosAdminNotifier,
    ServiciosAdminState>((ref) {
  return ServiciosAdminNotifier(
    ref.watch(servicioDatasourceProvider),
  );
});