import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/api_exception.dart';
import '../../data/remote/api/catalog_remote_datasource.dart';
import '../../data/remote/api/mantenimiento_remote_datasource.dart';
import '../../data/remote/api/servicio_remote_datasource.dart';
import '../../data/remote/api/user_remote_datasource.dart';
import '../../domain/model/mantenimiento.dart';
import '../../domain/model/moto.dart';
import '../../domain/model/servicio.dart';
import '../../domain/model/user.dart';

const estadosMantenimiento = <String>[
  'Pendiente',
  'En proceso',
  'Finalizado',
  'Cancelado',
];

class MantenimientosAdminState {
  final List<Mantenimiento> mantenimientos;

  final List<Moto> motos;
  final List<User> clientes;
  final List<Servicio> servicios;

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

  final MantenimientoFormState formState;

  const MantenimientosAdminState({
    this.mantenimientos = const [],
    this.motos = const [],
    this.clientes = const [],
    this.servicios = const [],
    this.isLoading = false,
    this.isLoadingCatalogos = false,
    this.error,
    this.catalogosError,
    this.search = '',
    this.filtroEstado,
    this.ordering = '-fecha_registro',
    this.page = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.formState = const MantenimientoFormIdle(),
  });

  MantenimientosAdminState copyWith({
    List<Mantenimiento>? mantenimientos,
    List<Moto>? motos,
    List<User>? clientes,
    List<Servicio>? servicios,
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
    MantenimientoFormState? formState,
  }) {
    return MantenimientosAdminState(
      mantenimientos:
          mantenimientos ?? this.mantenimientos,
      motos: motos ?? this.motos,
      clientes: clientes ?? this.clientes,
      servicios: servicios ?? this.servicios,
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

  Moto? motoPorId(int id) {
    for (final moto in motos) {
      if (moto.idMoto == id) {
        return moto;
      }
    }

    return null;
  }

  User? clientePorId(int id) {
    for (final cliente in clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }

    return null;
  }

  Servicio? servicioPorId(int id) {
    for (final servicio in servicios) {
      if (servicio.id == id) {
        return servicio;
      }
    }

    return null;
  }

  String nombreCliente(User cliente) {
    final nombreCompleto =
        '${cliente.firstName} ${cliente.lastName}'.trim();

    if (nombreCompleto.isNotEmpty) {
      return '$nombreCompleto (${cliente.username})';
    }

    return cliente.username;
  }
}



sealed class MantenimientoFormState {
  const MantenimientoFormState();
}

class MantenimientoFormIdle
    extends MantenimientoFormState {
  const MantenimientoFormIdle();
}

class MantenimientoFormSaving
    extends MantenimientoFormState {
  const MantenimientoFormSaving();
}

class MantenimientoFormSuccess
    extends MantenimientoFormState {
  final String message;

  const MantenimientoFormSuccess(this.message);
}

class MantenimientoFormError
    extends MantenimientoFormState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const MantenimientoFormError(
    this.message, {
    this.fieldErrors,
  });

  String? fieldError(String field) {
    return fieldErrors?[field]?.toString();
  }
}



class MantenimientosAdminNotifier
    extends StateNotifier<MantenimientosAdminState> {
  final MantenimientoRemoteDatasource
      _mantenimientoDatasource;
  final CatalogRemoteDatasource _catalogDatasource;
  final ServicioRemoteDatasource _servicioDatasource;
  final UserRemoteDatasource _userDatasource;

  MantenimientosAdminNotifier(
    this._mantenimientoDatasource,
    this._catalogDatasource,
    this._servicioDatasource,
    this._userDatasource,
  ) : super(const MantenimientosAdminState()) {
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
          await _mantenimientoDatasource
              .getMantenimientos(
        page: state.page,
        pageSize: state.pageSize,
        search: _textoONull(state.search),
        estado: state.filtroEstado,
        ordering: state.ordering,
      );

      state = state.copyWith(
        mantenimientos: response.results
            .map(
              (dto) => dto.toDomain(),
            )
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
      final motosResponse =
          await _catalogDatasource.getMotos(
        ordering: 'modelo',
        limit: 100,
        offset: 0,
      );

      final clientesResponse =
          await _userDatasource.getUsers(
        isStaff: false,
        isActive: true,
      );

      final serviciosResponse =
          await _servicioDatasource.getServicios(
        page: 1,
        pageSize: 100,
        estado: true,
        ordering: 'nombre',
      );

      final List<Moto> motos =
          List<Moto>.from(
        motosResponse.results,
      );

      final List<User> clientes =
          List<User>.from(
        clientesResponse.results,
      );

      final List<Servicio> servicios =
          serviciosResponse.results
              .map(
                (dto) => dto.toDomain(),
              )
              .toList();

      state = state.copyWith(
        motos: motos,
        clientes: clientes,
        servicios: servicios,
        isLoadingCatalogos: false,
        clearCatalogosError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingCatalogos: false,
        catalogosError:
            _obtenerMensajeError(error),
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
      ordering: '-fecha_registro',
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


  Future<void> crearMantenimiento({
    required int motoId,
    required int usuarioClienteId,
    required int servicioId,
    required int kilometrajeActual,
    String? diagnosticoInicial,
    required double costoFinal,
    String estado = 'Pendiente',
  }) async {
    state = state.copyWith(
      formState:
          const MantenimientoFormSaving(),
      clearError: true,
    );

    if (!_estadoValido(estado)) {
      state = state.copyWith(
        formState:
            const MantenimientoFormError(
          'El estado seleccionado no es válido.',
        ),
      );
      return;
    }

    if (kilometrajeActual < 0) {
      state = state.copyWith(
        formState:
            const MantenimientoFormError(
          'El kilometraje no puede ser negativo.',
          fieldErrors: {
            'kilometraje_actual':
                'El kilometraje no puede ser negativo.',
          },
        ),
      );
      return;
    }

    if (costoFinal < 0) {
      state = state.copyWith(
        formState:
            const MantenimientoFormError(
          'El costo final no puede ser negativo.',
          fieldErrors: {
            'costo_final':
                'El costo final no puede ser negativo.',
          },
        ),
      );
      return;
    }

    try {
      final creado =
          await _mantenimientoDatasource
              .createMantenimiento({
        'moto': motoId,
        'usuario_cliente': usuarioClienteId,
        'servicio': servicioId,
        'kilometraje_actual':
            kilometrajeActual,
        'diagnostico_inicial':
            _textoONull(diagnosticoInicial),
        'costo_final':
            costoFinal.toStringAsFixed(2),
        'estado': estado,
      });

      final mantenimientoCreado =
          creado.toDomain();

      state = state.copyWith(
        mantenimientos: [
          mantenimientoCreado,
          ...state.mantenimientos,
        ],
        total: state.total + 1,
        formState:
            const MantenimientoFormSuccess(
          'Mantenimiento creado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: MantenimientoFormError(
          _obtenerMensajeError(error),
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: MantenimientoFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }


  Future<void> actualizarMantenimiento({
    required int idMantenimiento,
    required int motoId,
    required int usuarioClienteId,
    required int servicioId,
    required int kilometrajeActual,
    String? diagnosticoInicial,
    required double costoFinal,
    required String estado,
  }) async {
    state = state.copyWith(
      formState:
          const MantenimientoFormSaving(),
      clearError: true,
    );

    if (!_estadoValido(estado)) {
      state = state.copyWith(
        formState:
            const MantenimientoFormError(
          'El estado seleccionado no es válido.',
        ),
      );
      return;
    }

    if (kilometrajeActual < 0) {
      state = state.copyWith(
        formState:
            const MantenimientoFormError(
          'El kilometraje no puede ser negativo.',
          fieldErrors: {
            'kilometraje_actual':
                'El kilometraje no puede ser negativo.',
          },
        ),
      );
      return;
    }

    if (costoFinal < 0) {
      state = state.copyWith(
        formState:
            const MantenimientoFormError(
          'El costo final no puede ser negativo.',
          fieldErrors: {
            'costo_final':
                'El costo final no puede ser negativo.',
          },
        ),
      );
      return;
    }

    try {
      final actualizado =
          await _mantenimientoDatasource
              .updateMantenimiento(
        idMantenimiento,
        {
          'moto': motoId,
          'usuario_cliente':
              usuarioClienteId,
          'servicio': servicioId,
          'kilometraje_actual':
              kilometrajeActual,
          'diagnostico_inicial':
              _textoONull(diagnosticoInicial),
          'costo_final':
              costoFinal.toStringAsFixed(2),
          'estado': estado,
        },
      );

      final mantenimientoActualizado =
          actualizado.toDomain();

      state = state.copyWith(
        mantenimientos:
            state.mantenimientos.map(
          (mantenimiento) {
            return mantenimiento
                        .idMantenimiento ==
                    idMantenimiento
                ? mantenimientoActualizado
                : mantenimiento;
          },
        ).toList(),
        formState:
            const MantenimientoFormSuccess(
          'Mantenimiento actualizado correctamente.',
        ),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        formState: MantenimientoFormError(
          _obtenerMensajeError(error),
          fieldErrors: error.fieldErrors,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        formState: MantenimientoFormError(
          _obtenerMensajeError(error),
        ),
      );
    }
  }


  Future<void> cambiarEstado(
    int idMantenimiento,
    String nuevoEstado,
  ) async {
    if (!_estadoValido(nuevoEstado)) {
      state = state.copyWith(
        error:
            'El estado seleccionado no es válido.',
      );
      return;
    }

    final mantenimientosAnteriores =
        state.mantenimientos;

    state = state.copyWith(
      mantenimientos:
          state.mantenimientos.map(
        (mantenimiento) {
          return mantenimiento.idMantenimiento ==
                  idMantenimiento
              ? mantenimiento.copyWith(
                  estado: nuevoEstado,
                )
              : mantenimiento;
        },
      ).toList(),
      clearError: true,
    );

    try {
      final actualizado =
          await _mantenimientoDatasource
              .patchMantenimiento(
        idMantenimiento,
        {
          'estado': nuevoEstado,
        },
      );

      final mantenimientoActualizado =
          actualizado.toDomain();

      state = state.copyWith(
        mantenimientos:
            state.mantenimientos.map(
          (mantenimiento) {
            return mantenimiento
                        .idMantenimiento ==
                    idMantenimiento
                ? mantenimientoActualizado
                : mantenimiento;
          },
        ).toList(),
      );

      if (state.filtroEstado != null) {
        await load();
      }
    } catch (error) {
      state = state.copyWith(
        mantenimientos:
            mantenimientosAnteriores,
        error: _obtenerMensajeError(error),
      );
    }
  }


  Future<void> eliminarMantenimiento(
    int idMantenimiento,
  ) async {
    final mantenimientosAnteriores =
        state.mantenimientos;
    final totalAnterior = state.total;

    state = state.copyWith(
      mantenimientos:
          state.mantenimientos
              .where(
                (mantenimiento) =>
                    mantenimiento
                        .idMantenimiento !=
                    idMantenimiento,
              )
              .toList(),
      total:
          state.total > 0 ? state.total - 1 : 0,
      clearError: true,
    );

    try {
      await _mantenimientoDatasource
          .deleteMantenimiento(
        idMantenimiento,
      );

      if (state.mantenimientos.isEmpty &&
          state.page > 1) {
        state = state.copyWith(
          page: state.page - 1,
        );

        await load();
      }
    } catch (error) {
      state = state.copyWith(
        mantenimientos:
            mantenimientosAnteriores,
        total: totalAnterior,
        error: _obtenerMensajeError(error),
      );
    }
  }


  void resetFormState() {
    state = state.copyWith(
      formState:
          const MantenimientoFormIdle(),
    );
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }



  bool _estadoValido(String estado) {
    return estadosMantenimiento.contains(estado);
  }

  String? _textoONull(String? value) {
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
        return 'El mantenimiento solicitado no existe.';
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

final mantenimientosAdminProvider =
    StateNotifierProvider<
        MantenimientosAdminNotifier,
        MantenimientosAdminState>((ref) {
  return MantenimientosAdminNotifier(
    ref.watch(mantenimientoDatasourceProvider),
    ref.watch(catalogDatasourceProvider),
    ref.watch(servicioDatasourceProvider),
    ref.watch(userDatasourceProvider),
  );
});