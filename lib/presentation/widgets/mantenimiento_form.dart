import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/mantenimiento.dart';
import '../../domain/model/moto.dart';
import '../../domain/model/servicio.dart';
import '../../domain/model/user.dart';
import '../../theme/app_colors.dart';
import '../providers/mantenimientos_admin_provider.dart';

Future<void> showMantenimientoForm(
  BuildContext context,
  WidgetRef ref, {
  Mantenimiento? initial,
}) {
  ref
      .read(mantenimientosAdminProvider.notifier)
      .resetFormState();

  final state = ref.read(mantenimientosAdminProvider);

  if (state.motos.isEmpty ||
      state.clientes.isEmpty ||
      state.servicios.isEmpty) {
    ref
        .read(mantenimientosAdminProvider.notifier)
        .cargarCatalogos();
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: MantenimientoFormSheet(
        initial: initial,
      ),
    ),
  );
}

class MantenimientoFormSheet
    extends ConsumerStatefulWidget {
  final Mantenimiento? initial;

  const MantenimientoFormSheet({
    super.key,
    this.initial,
  });

  @override
  ConsumerState<MantenimientoFormSheet>
      createState() {
    return _MantenimientoFormSheetState();
  }
}

class _MantenimientoFormSheetState
    extends ConsumerState<MantenimientoFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _kilometrajeController =
      TextEditingController();

  final _diagnosticoController =
      TextEditingController();

  final _costoController =
      TextEditingController();

  int? _motoId;
  int? _clienteId;
  int? _servicioId;

  String _estado = 'Pendiente';

  bool _cerrandoFormulario = false;

  @override
  void initState() {
    super.initState();

    final mantenimiento = widget.initial;

    if (mantenimiento != null) {
      _motoId = mantenimiento.motoId;
      _clienteId =
          mantenimiento.usuarioClienteId;
      _servicioId =
          mantenimiento.servicioId;

      _kilometrajeController.text =
          mantenimiento.kilometrajeActual
              .toString();

      _diagnosticoController.text =
          mantenimiento.diagnosticoInicial ??
              '';

      _costoController.text =
          mantenimiento.costoFinal
              .toStringAsFixed(2);

      _estado = mantenimiento.estado;
    }
  }

  @override
  void dispose() {
    _kilometrajeController.dispose();
    _diagnosticoController.dispose();
    _costoController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_motoId == null) {
      _mostrarError(
        'Selecciona una moto.',
      );
      return;
    }

    if (_clienteId == null) {
      _mostrarError(
        'Selecciona un cliente.',
      );
      return;
    }

    if (_servicioId == null) {
      _mostrarError(
        'Selecciona un servicio.',
      );
      return;
    }

    final kilometraje = int.tryParse(
      _kilometrajeController.text.trim(),
    );

    final costo = double.tryParse(
      _costoController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (kilometraje == null || costo == null) {
      return;
    }

    final notifier = ref.read(
      mantenimientosAdminProvider.notifier,
    );

    if (widget.initial == null) {
      await notifier.crearMantenimiento(
        motoId: _motoId!,
        usuarioClienteId: _clienteId!,
        servicioId: _servicioId!,
        kilometrajeActual: kilometraje,
        diagnosticoInicial:
            _diagnosticoController.text,
        costoFinal: costo,
        estado: _estado,
      );
    } else {
      await notifier.actualizarMantenimiento(
        idMantenimiento:
            widget.initial!.idMantenimiento,
        motoId: _motoId!,
        usuarioClienteId: _clienteId!,
        servicioId: _servicioId!,
        kilometrajeActual: kilometraje,
        diagnosticoInicial:
            _diagnosticoController.text,
        costoFinal: costo,
        estado: _estado,
      );
    }
  }

  void _seleccionarServicio(
    int? id,
    List<Servicio> servicios,
  ) {
    setState(() {
      _servicioId = id;

      final servicio = _buscarServicio(
        servicios,
        id,
      );

      if (servicio != null &&
          _costoController.text.trim().isEmpty) {
        _costoController.text =
            servicio.precioBase
                .toStringAsFixed(2);
      }
    });
  }

  Servicio? _buscarServicio(
    List<Servicio> servicios,
    int? id,
  ) {
    if (id == null) {
      return null;
    }

    for (final servicio in servicios) {
      if (servicio.id == id) {
        return servicio;
      }
    }

    return null;
  }

  String _nombreCliente(User cliente) {
    final nombreCompleto =
        '${cliente.firstName} ${cliente.lastName}'
            .trim();

    if (nombreCompleto.isNotEmpty) {
      return '$nombreCompleto (${cliente.username})';
    }

    return '${cliente.username} - ${cliente.email}';
  }

  String _nombreMoto(Moto moto) {
    return '${moto.marca.nombre} ${moto.modelo} '
        '${moto.anio} - ${moto.cilindraje} cc';
  }

  String _nombreServicio(
    Servicio servicio,
  ) {
    return '${servicio.nombre} - '
        '\$${servicio.precioBase.toStringAsFixed(2)}';
  }

  String? _validarKilometraje(
    String? value,
  ) {
    final texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El kilometraje es obligatorio';
    }

    final kilometraje = int.tryParse(texto);

    if (kilometraje == null) {
      return 'Ingresa un kilometraje válido';
    }

    if (kilometraje < 0) {
      return 'El kilometraje no puede ser negativo';
    }

    return null;
  }

  String? _validarCosto(
    String? value,
  ) {
    final texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El costo final es obligatorio';
    }

    final costo = double.tryParse(
      texto.replaceAll(',', '.'),
    );

    if (costo == null) {
      return 'Ingresa un costo válido';
    }

    if (costo < 0) {
      return 'El costo no puede ser negativo';
    }

    if (costo > 9999999999.99) {
      return 'El costo supera el valor permitido';
    }

    return null;
  }

  String? _errorBackend(
    MantenimientoFormState formState,
    String field,
  ) {
    if (formState
        is MantenimientoFormError) {
      return formState.fieldError(field);
    }

    return null;
  }

  void _mostrarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  int? _motoDisponible(
    List<Moto> motos,
  ) {
    if (_motoId == null) {
      return null;
    }

    final existe = motos.any(
      (moto) => moto.idMoto == _motoId,
    );

    return existe ? _motoId : null;
  }

  int? _clienteDisponible(
    List<User> clientes,
  ) {
    if (_clienteId == null) {
      return null;
    }

    final existe = clientes.any(
      (cliente) => cliente.id == _clienteId,
    );

    return existe ? _clienteId : null;
  }

  int? _servicioDisponible(
    List<Servicio> servicios,
  ) {
    if (_servicioId == null) {
      return null;
    }

    final existe = servicios.any(
      (servicio) =>
          servicio.id == _servicioId,
    );

    return existe ? _servicioId : null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      mantenimientosAdminProvider,
    );

    final formState = state.formState;

    final isSaving =
        formState is MantenimientoFormSaving;

    final isEdit = widget.initial != null;

    if (formState
            is MantenimientoFormSuccess &&
        !_cerrandoFormulario) {
      _cerrandoFormulario = true;

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final message = formState.message;

        Navigator.pop(context);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                AppColors.success,
          ),
        );
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context)
                .viewInsets
                .bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          8,
          24,
          32,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEdit
                  ? 'Editar mantenimiento '
                      '#${widget.initial!.idMantenimiento}'
                  : 'Nuevo mantenimiento',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (state.isLoadingCatalogos) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Cargando motos, clientes y servicios...',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (state.catalogosError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error
                      .withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.catalogosError!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(
                              mantenimientosAdminProvider
                                  .notifier,
                            )
                            .cargarCatalogos();
                      },
                      child: const Text(
                        'Reintentar',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (formState
                is MantenimientoFormError) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error
                      .withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formState.message,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value:
                        _motoDisponible(
                      state.motos,
                    ),
                    isExpanded: true,
                    dropdownColor:
                        AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: 'Moto *',
                      prefixIcon: Icon(
                        Icons.two_wheeler_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'moto',
                      ),
                    ),
                    items: state.motos
                        .map(
                          (moto) =>
                              DropdownMenuItem<int>(
                            value: moto.idMoto,
                            child: Text(
                              _nombreMoto(moto),
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isSaving ||
                            state.isLoadingCatalogos
                        ? null
                        : (value) {
                            setState(() {
                              _motoId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una moto';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<int>(
                    value:
                        _clienteDisponible(
                      state.clientes,
                    ),
                    isExpanded: true,
                    dropdownColor:
                        AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: 'Cliente *',
                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'usuario_cliente',
                      ),
                    ),
                    items: state.clientes
                        .map(
                          (cliente) =>
                              DropdownMenuItem<int>(
                            value: cliente.id,
                            child: Text(
                              _nombreCliente(cliente),
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isSaving ||
                            state.isLoadingCatalogos
                        ? null
                        : (value) {
                            setState(() {
                              _clienteId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un cliente';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<int>(
                    value:
                        _servicioDisponible(
                      state.servicios,
                    ),
                    isExpanded: true,
                    dropdownColor:
                        AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: 'Servicio *',
                      prefixIcon: Icon(
                        Icons.build_circle_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'servicio',
                      ),
                    ),
                    items: state.servicios
                        .map(
                          (servicio) =>
                              DropdownMenuItem<int>(
                            value: servicio.id,
                            child: Text(
                              _nombreServicio(
                                servicio,
                              ),
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isSaving ||
                            state.isLoadingCatalogos
                        ? null
                        : (value) {
                            _seleccionarServicio(
                              value,
                              state.servicios,
                            );
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un servicio';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        _kilometrajeController,
                    enabled: !isSaving,
                    keyboardType:
                        TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText:
                          'Kilometraje actual *',
                      prefixIcon: Icon(
                        Icons.speed_outlined,
                      ),
                      suffixText: 'km',
                      errorText: _errorBackend(
                        formState,
                        'kilometraje_actual',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator:
                        _validarKilometraje,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        _diagnosticoController,
                    enabled: !isSaving,
                    maxLines: 4,
                    textCapitalization:
                        TextCapitalization
                            .sentences,
                    decoration: InputDecoration(
                      labelText:
                          'Diagnóstico inicial',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          bottom: 68,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                        ),
                      ),
                      errorText: _errorBackend(
                        formState,
                        'diagnostico_inicial',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        _costoController,
                    enabled: !isSaving,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .allow(
                        RegExp(
                          r'^\d{0,10}([.,]\d{0,2})?$',
                        ),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Costo final *',
                      prefixText: '\$ ',
                      prefixIcon: Icon(
                        Icons.attach_money,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'costo_final',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarCosto,
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value:
                        estadosMantenimiento
                                .contains(_estado)
                            ? _estado
                            : 'Pendiente',
                    dropdownColor:
                        AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: 'Estado *',
                      prefixIcon: Icon(
                        Icons.info_outline,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'estado',
                      ),
                    ),
                    items: estadosMantenimiento
                        .map(
                          (estado) =>
                              DropdownMenuItem<
                                  String>(
                            value: estado,
                            child: Text(estado),
                          ),
                        )
                        .toList(),
                    onChanged: isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _estado = value;
                              });
                            }
                          },
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                          child: const Text(
                            'Cancelar',
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ||
                                  state
                                      .isLoadingCatalogos
                              ? null
                              : _submit,
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color:
                                        AppColors.onAccent,
                                  ),
                                )
                              : Text(
                                  isEdit
                                      ? 'Guardar cambios'
                                      : 'Crear mantenimiento',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}