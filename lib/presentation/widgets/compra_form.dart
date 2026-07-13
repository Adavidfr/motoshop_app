import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/compra.dart';
import '../../domain/model/moto.dart';
import '../../domain/model/proveedor.dart';
import '../../domain/model/repuesto.dart';
import '../../theme/app_colors.dart';
import '../providers/compras_admin_provider.dart';

enum TipoCompra {
  moto,
  repuesto,
}

Future<void> showCompraForm(
  BuildContext context,
  WidgetRef ref, {
  Compra? initial,
}) {
  ref.read(comprasAdminProvider.notifier).resetFormState();

  final state = ref.read(comprasAdminProvider);

  if (state.proveedores.isEmpty ||
      state.motos.isEmpty ||
      state.repuestos.isEmpty) {
    ref
        .read(comprasAdminProvider.notifier)
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
      child: CompraFormSheet(
        initial: initial,
      ),
    ),
  );
}

class CompraFormSheet extends ConsumerStatefulWidget {
  final Compra? initial;

  const CompraFormSheet({
    super.key,
    this.initial,
  });

  @override
  ConsumerState<CompraFormSheet> createState() {
    return _CompraFormSheetState();
  }
}

class _CompraFormSheetState
    extends ConsumerState<CompraFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();

  int? _proveedorId;
  int? _motoId;
  int? _repuestoId;

  TipoCompra _tipoCompra = TipoCompra.repuesto;
  String _estado = 'Pendiente';

  bool _cerrandoFormulario = false;

  @override
  void initState() {
    super.initState();

    final compra = widget.initial;

    if (compra != null) {
      _proveedorId = compra.proveedorId;
      _motoId = compra.motoId;
      _repuestoId = compra.repuestoId;
      _cantidadController.text =
          compra.cantidad.toString();
      _precioController.text =
          compra.precioUnitario.toStringAsFixed(2);
      _estado = compra.estado;

      _tipoCompra = compra.motoId != null
          ? TipoCompra.moto
          : TipoCompra.repuesto;
    }

    _cantidadController.addListener(_actualizarSubtotal);
    _precioController.addListener(_actualizarSubtotal);
  }

  @override
  void dispose() {
    _cantidadController
        .removeListener(_actualizarSubtotal);
    _precioController
        .removeListener(_actualizarSubtotal);

    _cantidadController.dispose();
    _precioController.dispose();

    super.dispose();
  }

  void _actualizarSubtotal() {
    if (mounted) {
      setState(() {});
    }
  }

  double get _subtotal {
    final cantidad = int.tryParse(
          _cantidadController.text.trim(),
        ) ??
        0;

    final precio = double.tryParse(
          _precioController.text
              .trim()
              .replaceAll(',', '.'),
        ) ??
        0;

    return cantidad * precio;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_proveedorId == null) {
      _mostrarMensaje(
        'Selecciona un proveedor.',
      );
      return;
    }

    if (_tipoCompra == TipoCompra.moto &&
        _motoId == null) {
      _mostrarMensaje(
        'Selecciona una moto.',
      );
      return;
    }

    if (_tipoCompra == TipoCompra.repuesto &&
        _repuestoId == null) {
      _mostrarMensaje(
        'Selecciona un repuesto.',
      );
      return;
    }

    final cantidad = int.tryParse(
      _cantidadController.text.trim(),
    );

    final precioUnitario = double.tryParse(
      _precioController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (cantidad == null || precioUnitario == null) {
      return;
    }

    final notifier = ref.read(
      comprasAdminProvider.notifier,
    );

    final motoId = _tipoCompra == TipoCompra.moto
        ? _motoId
        : null;

    final repuestoId =
        _tipoCompra == TipoCompra.repuesto
            ? _repuestoId
            : null;

    if (widget.initial == null) {
      await notifier.crearCompra(
        proveedorId: _proveedorId!,
        motoId: motoId,
        repuestoId: repuestoId,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        estado: _estado,
      );
    } else {
      await notifier.actualizarCompra(
        idCompra: widget.initial!.idCompra,
        proveedorId: _proveedorId!,
        motoId: motoId,
        repuestoId: repuestoId,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        estado: _estado,
      );
    }
  }

  void _seleccionarTipo(TipoCompra tipo) {
    setState(() {
      _tipoCompra = tipo;

      if (tipo == TipoCompra.moto) {
        _repuestoId = null;
      } else {
        _motoId = null;
      }

      _precioController.clear();
    });
  }

  void _seleccionarMoto(
    int? id,
    List<Moto> motos,
  ) {
    setState(() {
      _motoId = id;

      final moto = _buscarMoto(
        motos,
        id,
      );

      if (moto != null) {
        _precioController.text =
            moto.precio.toStringAsFixed(2);
      }
    });
  }

  void _seleccionarRepuesto(
    int? id,
    List<Repuesto> repuestos,
  ) {
    setState(() {
      _repuestoId = id;

      final repuesto = _buscarRepuesto(
        repuestos,
        id,
      );

      if (repuesto != null) {
        // En una compra se utiliza el costo,
        // no el precio de venta.
        _precioController.text =
            repuesto.costo.toStringAsFixed(2);
      }
    });
  }

  Moto? _buscarMoto(
    List<Moto> motos,
    int? id,
  ) {
    if (id == null) {
      return null;
    }

    for (final moto in motos) {
      if (moto.idMoto == id) {
        return moto;
      }
    }

    return null;
  }

  Repuesto? _buscarRepuesto(
    List<Repuesto> repuestos,
    int? id,
  ) {
    if (id == null) {
      return null;
    }

    for (final repuesto in repuestos) {
      if (repuesto.idRepuesto == id) {
        return repuesto;
      }
    }

    return null;
  }

  String? _validarCantidad(String? value) {
    final texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'La cantidad es obligatoria';
    }

    final cantidad = int.tryParse(texto);

    if (cantidad == null) {
      return 'Ingresa una cantidad válida';
    }

    if (cantidad <= 0) {
      return 'La cantidad debe ser mayor que cero';
    }

    return null;
  }

  String? _validarPrecio(String? value) {
    final texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El precio unitario es obligatorio';
    }

    final precio = double.tryParse(
      texto.replaceAll(',', '.'),
    );

    if (precio == null) {
      return 'Ingresa un precio válido';
    }

    if (precio <= 0) {
      return 'El precio debe ser mayor que cero';
    }

    if (precio > 9999999999.99) {
      return 'El precio supera el valor permitido';
    }

    return null;
  }

  String? _errorBackend(
    CompraFormState formState,
    String field,
  ) {
    if (formState is CompraFormError) {
      return formState.fieldError(field);
    }

    return null;
  }

  void _mostrarMensaje(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comprasAdminProvider);

    final formState = state.formState;
    final isSaving = formState is CompraFormSaving;
    final isEdit = widget.initial != null;

    if (formState is CompraFormSuccess &&
        !_cerrandoFormulario) {
      _cerrandoFormulario = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final message = formState.message;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom,
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
                margin: const EdgeInsets.symmetric(
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
                  ? 'Editar compra #${widget.initial!.idCompra}'
                  : 'Nueva compra',
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
                      'Cargando proveedores, motos y repuestos...',
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
                  color: AppColors.error.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Column(
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
                              comprasAdminProvider
                                  .notifier,
                            )
                            .cargarCatalogos();
                      },
                      child:
                          const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (formState is CompraFormError) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(
                      alpha: 0.25,
                    ),
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
                        _valorDisponibleProveedor(
                      state.proveedores,
                    ),
                    isExpanded: true,
                    dropdownColor: AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: 'Proveedor *',
                      prefixIcon: Icon(
                        Icons.local_shipping_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'proveedor',
                      ),
                    ),
                    items: state.proveedores
                        .map(
                          (proveedor) =>
                              DropdownMenuItem<int>(
                            value: proveedor.id,
                            child: Text(
                              proveedor.nombre,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged:
                        isSaving ||
                                state
                                    .isLoadingCatalogos
                            ? null
                            : (value) {
                                setState(() {
                                  _proveedorId =
                                      value;
                                });
                              },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un proveedor';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tipo de compra *',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                AppColors.textSecondary,
                          ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child:
                        SegmentedButton<TipoCompra>(
                      segments: const [
                        ButtonSegment<TipoCompra>(
                          value: TipoCompra.moto,
                          label: Text('Moto'),
                          icon: Icon(
                            Icons.two_wheeler_outlined,
                          ),
                        ),
                        ButtonSegment<TipoCompra>(
                          value: TipoCompra.repuesto,
                          label: Text('Repuesto'),
                          icon: Icon(
                            Icons.settings_outlined,
                          ),
                        ),
                      ],
                      selected: <TipoCompra>{
                        _tipoCompra,
                      },
                      onSelectionChanged: isSaving
                          ? null
                          : (values) {
                              _seleccionarTipo(
                                values.first,
                              );
                            },
                      showSelectedIcon: false,
                      expandedInsets: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_tipoCompra ==
                      TipoCompra.moto)
                    DropdownButtonFormField<int>(
                      value:
                          _valorDisponibleMoto(
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
                                '${moto.modelo} - ${moto.anio} - ${moto.cilindraje} cc',
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          isSaving ||
                                  state
                                      .isLoadingCatalogos
                              ? null
                              : (value) {
                                  _seleccionarMoto(
                                    value,
                                    state.motos,
                                  );
                                },
                      validator: (value) {
                        if (_tipoCompra ==
                                TipoCompra.moto &&
                            value == null) {
                          return 'Selecciona una moto';
                        }

                        return null;
                      },
                    ),

                  if (_tipoCompra ==
                      TipoCompra.repuesto)
                    DropdownButtonFormField<int>(
                      value:
                          _valorDisponibleRepuesto(
                        state.repuestos,
                      ),
                      isExpanded: true,
                      dropdownColor:
                          AppColors.surface2,
                      decoration: InputDecoration(
                        labelText: 'Repuesto *',
                        prefixIcon: Icon(
                          Icons.settings_outlined,
                        ),
                        errorText: _errorBackend(
                          formState,
                          'repuesto',
                        ),
                      ),
                      items: state.repuestos
                          .map(
                            (repuesto) =>
                                DropdownMenuItem<int>(
                              value:
                                  repuesto.idRepuesto,
                              child: Text(
                                '${repuesto.nombre} (${repuesto.sku})',
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          isSaving ||
                                  state
                                      .isLoadingCatalogos
                              ? null
                              : (value) {
                                  _seleccionarRepuesto(
                                    value,
                                    state.repuestos,
                                  );
                                },
                      validator: (value) {
                        if (_tipoCompra ==
                                TipoCompra.repuesto &&
                            value == null) {
                          return 'Selecciona un repuesto';
                        }

                        return null;
                      },
                    ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        _cantidadController,
                    enabled: !isSaving,
                    keyboardType:
                        TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Cantidad *',
                      prefixIcon: Icon(
                        Icons.numbers_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'cantidad',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarCantidad,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller:
                        _precioController,
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
                      labelText:
                          'Precio unitario *',
                      prefixText: '\$ ',
                      prefixIcon: Icon(
                        Icons.attach_money,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'precio_unitario',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarPrecio,
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Subtotal',
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '\$ ${_subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: estadosCompra
                            .contains(_estado)
                        ? _estado
                        : 'Pendiente',
                    dropdownColor: AppColors.surface2,
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
                    items: estadosCompra
                        .map(
                          (estado) =>
                              DropdownMenuItem<String>(
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
                              : () =>
                                  Navigator.pop(context),
                          child:
                              const Text('Cancelar'),
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
                                      : 'Crear compra',
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

  int? _valorDisponibleProveedor(
    List<Proveedor> proveedores,
  ) {
    if (_proveedorId == null) {
      return null;
    }

    final existe = proveedores.any(
      (proveedor) =>
          proveedor.id == _proveedorId,
    );

    return existe ? _proveedorId : null;
  }

  int? _valorDisponibleMoto(
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

  int? _valorDisponibleRepuesto(
    List<Repuesto> repuestos,
  ) {
    if (_repuestoId == null) {
      return null;
    }

    final existe = repuestos.any(
      (repuesto) =>
          repuesto.idRepuesto == _repuestoId,
    );

    return existe ? _repuestoId : null;
  }
}