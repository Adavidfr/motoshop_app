import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/api_exception.dart';
import '../../data/remote/api/catalog_remote_datasource.dart';
import '../../data/remote/api/compra_remote_datasource.dart';
import '../../data/remote/api/inventory_remote_datasource.dart';
import '../../data/remote/api/proveedor_remote_datasource.dart';
import '../../domain/model/compra.dart';
import '../../domain/model/moto.dart';
import '../../domain/model/proveedor.dart';
import '../../domain/model/repuesto.dart';

const estadosCompra = <String>[
  'Pendiente',
  'Recibida',
  'Cancelada',
];

class ComprasAdminState {
  final List<Compra> compras;

  final List<Proveedor> proveedores;
  final List<Moto> motos;
  final List<Repuesto> repuestos;

  final bool isLoading;
  final bool isLoadingCatalogos;
  final String? error;
  final String? catalogosError;

  final String search;
  final String? filtroEstado;
  final String ordering;

  final int page;
  final int pageSize;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  final CompraFormState formState;

  const ComprasAdminState({
    this.compras = const [],
    this.proveedores = const [],
    this.motos = const [],
    this.repuestos = const [],
    this.isLoading = false,
    this.isLoadingCatalogos = false,
    this.error,
    this.catalogosError,
    this.search = '',
    this.filtroEstado,
    this.ordering = '-fecha_compra',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const CompraFormIdle(),
  });

  ComprasAdminState copyWith({
    List<Compra>? compras,
    List<Proveedor>? proveedores,
    List<Moto>? motos,
    List<Repuesto>? repuestos,
    bool? isLoading,
    bool? isLoadingCatalogos,
    String? error,
    bool clearError = false,
    String? catalogosError,
    bool clearCatalogosError = false,
    String? search,
    String? filtroEstado,
    bool clearFiltroEstado = false,
    String? ordering,
    int? page,
    int? pageSize,
    int? total,
    bool? hasNextPage,
    bool? hasPreviousPage,
    CompraFormState? formState,
  }) {
    return ComprasAdminState(
      compras: compras ?? this.compras,
      proveedores: proveedores ?? this.proveedores,
      motos: motos ?? this.motos,
      repuestos: repuestos ?? this.repuestos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingCatalogos:
          isLoadingCatalogos ?? this.isLoadingCatalogos,
      error: clearError ? null : error ?? this.error,
      catalogosError: clearCatalogosError
          ? null
          : catalogosError ?? this.catalogosError,
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

  Proveedor? proveedorPorId(int id) {
    for (final proveedor in proveedores) {
      if (proveedor.id == id) {
        return proveedor;
      }
    }

    return null;
  }

  Moto? motoPorId(int id) {
    for (final moto in motos) {
      if (moto.idMoto == id) {
        return moto;
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

sealed class CompraFormState {
  const CompraFormState();
}

class CompraFormIdle extends CompraFormState {
  const CompraFormIdle();
}

class CompraFormSaving extends CompraFormState {
  const CompraFormSaving();
}

class CompraFormSuccess extends CompraFormState {
  final String message;

  const CompraFormSuccess(this.message);
}

class CompraFormError extends CompraFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const CompraFormError(
    this.message, {
    this.fieldErrors,
  });

  String? fieldError(String field) {
    return fieldErrors?[field]?.toString();
  }
}

class ComprasAdminNotifier
    extends StateNotifier<ComprasAdminState> {
  final CompraRemoteDatasource _compraDatasource;
  final ProveedorRemoteDatasource _proveedorDatasource;
  final CatalogRemoteDatasource _catalogDatasource;
  final InventoryRemoteDatasource _inventoryDatasource;

  ComprasAdminNotifier(
    this._compraDatasource,
    this._proveedorDatasource,
    this._catalogDatasource,
    this._inventoryDatasource,
  ) : super(const ComprasAdminState()) {
    load();
    cargarCatalogos();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await _compraDatasource.getCompras(
        page: state.page,
        pageSize: state.pageSize,
        search: _textoONull(state.search),
        estado: state.filtroEstado,
        ordering: state.ordering,
      );

      state = state.copyWith(
        compras: response.results
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
        error: _obtenerMensajeError(error),
      );
    }
  }

  Future<void> cargarCatalogos() async {
  state = state.copyWith(
    isLoadingCatalogos: true,
    clearCatalogosError: true,
  );

  try {
    final proveedoresResponse =
        await _proveedorDatasource.getProveedores(
      page: 1,
      pageSize: 100,
      estado: true,
      ordering: 'nombre',
    );


    final motosResponse =
        await _catalogDatasource.getMotos(
      ordering: 'modelo',
      limit: 100,
      offset: 0,
    );

   
    final repuestosResponse =
        await _inventoryDatasource.getRepuestos(
      ordering: 'nombre',
      limit: 100,
      offset: 0,
    );

    final List<Proveedor> proveedores =
        proveedoresResponse.results
            .map(
              (dto) => dto.toDomain(),
            )
            .toList();

    final List<Moto> motos =
        List<Moto>.from(
      motosResponse.results,
    );

    final List<Repuesto> repuestos =
        List<Repuesto>.from(
      repuestosResponse.results,
    );

    state = state.copyWith(
      proveedores: proveedores,
      motos: motos,
      repuestos: repuestos,
      isLoadingCatalogos: false,
      clearCatalogosError: true,
    );
  } catch (error) {
    state = state.copyWith(
      isLoadingCatalogos: false,
      catalogosError: _obtenerMensajeError(error),
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

  Future<void> setFiltroEstado(
    String? estado,
  ) async {
    if (estado == null || estado.isEmpty) {
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

  Future<void> setOrdering(
    String value,
  ) async {
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
      ordering: '-fecha_compra',
      page: 1,
    );

    await load();
  }

  Future<void> siguientePagina() async {
    if (state.isLoading ||
        !state.hasNextPage) {
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

  Future<void> setPageSize(
    int value,
  ) async {
    if (value <= 0) {
      return;
    }

    state = state.copyWith(
      pageSize: value,
      page: 1,
    );

    await load();
  }

  Future<void> crearCompra({
    required int proveedorId,
    int? motoId,
    int? repuestoId,
    required int cantidad,
    required double precioUnitario,
    String estado = 'Pendiente',
  }) async {
    state = state.copyWith(
      formState: const CompraFormSaving(),
      clearError: true,
    );

    if (!_seleccionProductoValida(
      motoId: motoId,
      repuestoId: repuestoId,
    )) {
      state = state.copyWith(
        formState: const CompraFormError(
          'Debes seleccionar solamente una moto o un repuesto.',
        ),
      );
      return;
    }

    if (cantidad <= 0) {
      state = state.copyWith(
        formState: const CompraFormError(
          'La cantidad debe ser mayor que cero.',
          fieldErrors: {
            'cantidad':
                'La cantidad debe ser mayor que cero.',
          },
        ),
      );
      return;
    }

    if (precioUnitario <= 0) {
      state = state.copyWith(
        formState: const CompraFormError(
          'El precio unitario debe ser mayor que cero.',
          fieldErrors: {
            'precio_unitario':
                'El precio unitario debe ser mayor que cero.',
          },
        ),
      );
      return;
    }

    final subtotal = cantidad * precioUnitario;

    try {
      final creada =
          await _compraDatasource.createCompra({
        'proveedor': proveedorId,
        'moto': motoId,
        'repuesto': repuestoId,
        'cantidad': cantidad,
        'precio_unitario':
            precioUnitario.toStringAsFixed(2),
        'subtotal': subtotal.toStringAsFixed(2),
        'estado': estado,
      });

      final compraCreada = creada.toDomain();

      state = state.copyWith(
        compras: [
          compraCreada,
          ...state.compras,
        ],
        total: state.total + 1,
        formState: const CompraFormSuccess(
          'Compra creada correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: CompraFormError(
          _obtenerMensajeError(error),
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: CompraFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }

  Future<void> actualizarCompra({
    required int idCompra,
    required int proveedorId,
    int? motoId,
    int? repuestoId,
    required int cantidad,
    required double precioUnitario,
    required String estado,
  }) async {
    state = state.copyWith(
      formState: const CompraFormSaving(),
      clearError: true,
    );

    if (!_seleccionProductoValida(
      motoId: motoId,
      repuestoId: repuestoId,
    )) {
      state = state.copyWith(
        formState: const CompraFormError(
          'Debes seleccionar solamente una moto o un repuesto.',
        ),
      );
      return;
    }

    if (cantidad <= 0 ||
        precioUnitario <= 0) {
      state = state.copyWith(
        formState: const CompraFormError(
          'La cantidad y el precio deben ser mayores que cero.',
        ),
      );
      return;
    }

    final subtotal = cantidad * precioUnitario;

    try {
      final actualizada =
          await _compraDatasource.updateCompra(
        idCompra,
        {
          'proveedor': proveedorId,
          'moto': motoId,
          'repuesto': repuestoId,
          'cantidad': cantidad,
          'precio_unitario':
              precioUnitario.toStringAsFixed(2),
          'subtotal': subtotal.toStringAsFixed(2),
          'estado': estado,
        },
      );

      final compraActualizada =
          actualizada.toDomain();

      state = state.copyWith(
        compras: state.compras.map((compra) {
          return compra.idCompra == idCompra
              ? compraActualizada
              : compra;
        }).toList(),
        formState: const CompraFormSuccess(
          'Compra actualizada correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: CompraFormError(
          _obtenerMensajeError(error),
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: CompraFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }

  Future<void> cambiarEstado(
    int idCompra,
    String nuevoEstado,
  ) async {
    final comprasAnteriores = state.compras;

    state = state.copyWith(
      compras: state.compras.map((compra) {
        return compra.idCompra == idCompra
            ? compra.copyWith(
                estado: nuevoEstado,
              )
            : compra;
      }).toList(),
      clearError: true,
    );

    try {
      final actualizada =
          await _compraDatasource.patchCompra(
        idCompra,
        {
          'estado': nuevoEstado,
        },
      );

      final compraActualizada =
          actualizada.toDomain();

      state = state.copyWith(
        compras: state.compras.map((compra) {
          return compra.idCompra == idCompra
              ? compraActualizada
              : compra;
        }).toList(),
      );

      if (state.filtroEstado != null) {
        await load();
      }
    } catch (error) {
      state = state.copyWith(
        compras: comprasAnteriores,
        error: _obtenerMensajeError(error),
      );
    }
  }

  Future<void> eliminarCompra(
    int idCompra,
  ) async {
    final comprasAnteriores = state.compras;
    final totalAnterior = state.total;

    state = state.copyWith(
      compras: state.compras
          .where(
            (compra) =>
                compra.idCompra != idCompra,
          )
          .toList(),
      total:
          state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );

    try {
      await _compraDatasource.deleteCompra(
        idCompra,
      );

      if (state.compras.isEmpty &&
          state.page > 1) {
        state = state.copyWith(
          page: state.page - 1,
        );

        await load();
      }
    } catch (error) {
      state = state.copyWith(
        compras: comprasAnteriores,
        total: totalAnterior,
        error: _obtenerMensajeError(error),
      );
    }
  }

  void resetFormState() {
    state = state.copyWith(
      formState: const CompraFormIdle(),
    );
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  bool _seleccionProductoValida({
    required int? motoId,
    required int? repuestoId,
  }) {
    final tieneMoto = motoId != null;
    final tieneRepuesto = repuestoId != null;

    return tieneMoto != tieneRepuesto;
  }

  String? _textoONull(
    String? value,
  ) {
    final texto = value?.trim();

    if (texto == null || texto.isEmpty) {
      return null;
    }

    return texto;
  }

  String _obtenerMensajeError(
    Object error,
  ) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
      }

      if (error.statusCode == 403) {
        return 'No tienes permisos de administrador para realizar esta acción.';
      }

      if (error.statusCode == 404) {
        return 'La compra solicitada no existe.';
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

final comprasAdminProvider = StateNotifierProvider<
    ComprasAdminNotifier,
    ComprasAdminState>((ref) {
  return ComprasAdminNotifier(
    ref.watch(compraDatasourceProvider),
    ref.watch(proveedorDatasourceProvider),
    ref.watch(catalogDatasourceProvider),
    ref.watch(inventoryDatasourceProvider),
  );
});