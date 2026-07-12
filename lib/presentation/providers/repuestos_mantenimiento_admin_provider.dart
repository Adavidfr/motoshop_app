import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/inventory_remote_datasource.dart';
import '../../data/remote/api/mantenimiento_remote_datasource.dart';
import '../../data/remote/api/repuesto_mantenimiento_remote_datasource.dart';
import '../../domain/model/mantenimiento.dart';
import '../../domain/model/repuesto.dart';
import '../../domain/model/repuesto_mantenimiento.dart';

class RepuestosMantenimientoAdminState {
  final List<RepuestoMantenimiento> registros;
  final List<Mantenimiento> mantenimientos;
  final List<Repuesto> repuestos;

  final bool isLoading;
  final bool isLoadingCatalogos;
  final String? error;
  final String? catalogosError;

  final String search;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final RepuestoMantenimientoFormState formState;

  const RepuestosMantenimientoAdminState({
    this.registros = const [],
    this.mantenimientos = const [],
    this.repuestos = const [],
    this.isLoading = false,
    this.isLoadingCatalogos = false,
    this.error,
    this.catalogosError,
    this.search = '',
    this.ordering = 'id_repuesto_mantenimiento',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState =
        const RepuestoMantenimientoFormIdle(),
  });

  RepuestosMantenimientoAdminState copyWith({
    List<RepuestoMantenimiento>? registros,
    List<Mantenimiento>? mantenimientos,
    List<Repuesto>? repuestos,
    bool? isLoading,
    bool? isLoadingCatalogos,
    String? error,
    bool clearError = false,
    String? catalogosError,
    bool clearCatalogosError = false,
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    RepuestoMantenimientoFormState? formState,
  }) {
    return RepuestosMantenimientoAdminState(
      registros: registros ?? this.registros,
      mantenimientos:
          mantenimientos ?? this.mantenimientos,
      repuestos: repuestos ?? this.repuestos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingCatalogos:
          isLoadingCatalogos ?? this.isLoadingCatalogos,
      error: clearError ? null : error ?? this.error,
      catalogosError: clearCatalogosError
          ? null
          : catalogosError ?? this.catalogosError,
      search: search ?? this.search,
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

  Mantenimiento? mantenimientoPorId(int id) {
    for (final mantenimiento in mantenimientos) {
      if (mantenimiento.idMantenimiento == id) {
        return mantenimiento;
      }
    }

    return null;
  }

  Repuesto? repuestoPorId(int id) {
    for (final repuesto in repuestos) {
      if (repuesto.idRepuesto == id) {
        return repuesto;
      }
    }

    return null;
  }
}

sealed class RepuestoMantenimientoFormState {
  const RepuestoMantenimientoFormState();
}

class RepuestoMantenimientoFormIdle
    extends RepuestoMantenimientoFormState {
  const RepuestoMantenimientoFormIdle();
}

class RepuestoMantenimientoFormSaving
    extends RepuestoMantenimientoFormState {
  const RepuestoMantenimientoFormSaving();
}

class RepuestoMantenimientoFormSuccess
    extends RepuestoMantenimientoFormState {
  final String message;

  const RepuestoMantenimientoFormSuccess(
    this.message,
  );
}

class RepuestoMantenimientoFormError
    extends RepuestoMantenimientoFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const RepuestoMantenimientoFormError(
    this.message, {
    this.fieldErrors,
  });

  String? fieldError(String field) {
    return fieldErrors?[field]?.toString();
  }
}

class RepuestosMantenimientoAdminNotifier
    extends StateNotifier<
        RepuestosMantenimientoAdminState> {
  final RepuestoMantenimientoRemoteDatasource
      _datasource;

  final MantenimientoRemoteDatasource
      _mantenimientoDatasource;

  final InventoryRemoteDatasource
      _inventoryDatasource;

  RepuestosMantenimientoAdminNotifier(
    this._datasource,
    this._mantenimientoDatasource,
    this._inventoryDatasource,
  ) : super(
          const RepuestosMantenimientoAdminState(),
        ) {
    load();
    cargarCatalogos();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final response =
          await _datasource.getRepuestosMantenimiento(
        page: state.page,
        pageSize: state.pageSize,
        search: state.search.trim().isEmpty
            ? null
            : state.search.trim(),
        ordering: state.ordering,
      );

      state = state.copyWith(
        registros: response.results
            .map((dto) => dto.toDomain())
            .toList(),
        total: response.count,
        hasNextPage: response.next != null,
        hasPreviousPage: response.previous != null,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _mensajeError(error),
      );
    }
  }

  Future<void> cargarCatalogos() async {
    state = state.copyWith(
      isLoadingCatalogos: true,
      clearCatalogosError: true,
    );

    try {
      final mantenimientosResponse =
          await _mantenimientoDatasource
              .getMantenimientos(
        page: 1,
        pageSize: 100,
        ordering: '-fecha_registro',
      );

      final repuestosResponse =
          await _inventoryDatasource.getRepuestos(
        ordering: 'nombre',
        limit: 100,
        offset: 0,
      );

      final mantenimientos =
          mantenimientosResponse.results
              .map((dto) => dto.toDomain())
              .toList();

      final repuestos = List<Repuesto>.from(
        repuestosResponse.results,
      );

      state = state.copyWith(
        mantenimientos: mantenimientos,
        repuestos: repuestos,
        isLoadingCatalogos: false,
        clearCatalogosError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingCatalogos: false,
        catalogosError: _mensajeError(error),
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

  Future<void> setOrdering(String value) async {
    state = state.copyWith(
      ordering: value,
      page: 1,
    );

    await load();
  }

  Future<void> siguientePagina() async {
    if (state.isLoading || !state.hasNextPage) {
      return;
    }

    state = state.copyWith(page: state.page + 1);
    await load();
  }

  Future<void> paginaAnterior() async {
    if (state.isLoading ||
        !state.hasPreviousPage ||
        state.page <= 1) {
      return;
    }

    state = state.copyWith(page: state.page - 1);
    await load();
  }

  Future<void> setPageSize(int value) async {
    if (value <= 0) return;

    state = state.copyWith(
      pageSize: value,
      page: 1,
    );

    await load();
  }

  Future<void> crear({
    required int mantenimientoId,
    required int repuestoId,
    required int cantidad,
    required double precioUnitario,
  }) async {
    state = state.copyWith(
      formState:
          const RepuestoMantenimientoFormSaving(),
    );

    if (cantidad <= 0 || precioUnitario <= 0) {
      state = state.copyWith(
        formState:
            const RepuestoMantenimientoFormError(
          'La cantidad y el precio deben ser mayores que cero.',
        ),
      );
      return;
    }

    final subtotal = cantidad * precioUnitario;

    try {
      final creado =
          await _datasource.createRepuestoMantenimiento({
        'mantenimiento': mantenimientoId,
        'repuesto': repuestoId,
        'cantidad': cantidad,
        'precio_unitario':
            precioUnitario.toStringAsFixed(2),
        'subtotal': subtotal.toStringAsFixed(2),
      });

      state = state.copyWith(
        registros: [
          creado.toDomain(),
          ...state.registros,
        ],
        total: state.total + 1,
        formState:
            const RepuestoMantenimientoFormSuccess(
          'Repuesto agregado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState:
            RepuestoMantenimientoFormError(
          error.message,
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState:
            RepuestoMantenimientoFormError(
          _mensajeError(error),
        ),
      );
    }
  }

  Future<void> actualizar({
    required int id,
    required int mantenimientoId,
    required int repuestoId,
    required int cantidad,
    required double precioUnitario,
  }) async {
    state = state.copyWith(
      formState:
          const RepuestoMantenimientoFormSaving(),
    );

    final subtotal = cantidad * precioUnitario;

    try {
      final actualizado =
          await _datasource.updateRepuestoMantenimiento(
        id,
        {
          'mantenimiento': mantenimientoId,
          'repuesto': repuestoId,
          'cantidad': cantidad,
          'precio_unitario':
              precioUnitario.toStringAsFixed(2),
          'subtotal': subtotal.toStringAsFixed(2),
        },
      );

      final domain = actualizado.toDomain();

      state = state.copyWith(
        registros: state.registros.map((registro) {
          return registro.idRepuestoMantenimiento == id
              ? domain
              : registro;
        }).toList(),
        formState:
            const RepuestoMantenimientoFormSuccess(
          'Registro actualizado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState:
            RepuestoMantenimientoFormError(
          error.message,
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState:
            RepuestoMantenimientoFormError(
          _mensajeError(error),
        ),
      );
    }
  }

  Future<void> eliminar(int id) async {
    final anteriores = state.registros;
    final totalAnterior = state.total;

    state = state.copyWith(
      registros: state.registros
          .where(
            (registro) =>
                registro.idRepuestoMantenimiento != id,
          )
          .toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );

    try {
      await _datasource.deleteRepuestoMantenimiento(id);
    } catch (error) {
      state = state.copyWith(
        registros: anteriores,
        total: totalAnterior,
        error: _mensajeError(error),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(
      formState:
          const RepuestoMantenimientoFormIdle(),
    );
  }

  String _mensajeError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('ApiException: ', '');
  }
}

final repuestosMantenimientoAdminProvider =
    StateNotifierProvider<
        RepuestosMantenimientoAdminNotifier,
        RepuestosMantenimientoAdminState>((ref) {
  return RepuestosMantenimientoAdminNotifier(
    ref.watch(
      repuestoMantenimientoDatasourceProvider,
    ),
    ref.watch(mantenimientoDatasourceProvider),
    ref.watch(inventoryDatasourceProvider),
  );
});