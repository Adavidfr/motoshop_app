import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/repuesto_mantenimiento.dart';
import '../../theme/app_colors.dart';
import '../providers/repuestos_mantenimiento_admin_provider.dart';

Future<void> showRepuestoMantenimientoForm(
  BuildContext context,
  WidgetRef ref, {
  RepuestoMantenimiento? initial,
}) {
  ref
      .read(
        repuestosMantenimientoAdminProvider.notifier,
      )
      .resetFormState();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: RepuestoMantenimientoFormSheet(
        initial: initial,
      ),
    ),
  );
}

class RepuestoMantenimientoFormSheet
    extends ConsumerStatefulWidget {
  final RepuestoMantenimiento? initial;

  const RepuestoMantenimientoFormSheet({
    super.key,
    this.initial,
  });

  @override
  ConsumerState<RepuestoMantenimientoFormSheet>
      createState() =>
          _RepuestoMantenimientoFormSheetState();
}

class _RepuestoMantenimientoFormSheetState
    extends ConsumerState<
        RepuestoMantenimientoFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();

  int? _mantenimientoId;
  int? _repuestoId;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();

    final registro = widget.initial;

    if (registro != null) {
      _mantenimientoId = registro.mantenimientoId;
      _repuestoId = registro.repuestoId;
      _cantidadController.text =
          registro.cantidad.toString();
      _precioController.text =
          registro.precioUnitario.toStringAsFixed(2);
    }

    _cantidadController.addListener(_actualizar);
    _precioController.addListener(_actualizar);
  }

  @override
  void dispose() {
    _cantidadController.removeListener(_actualizar);
    _precioController.removeListener(_actualizar);
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  double get _subtotal {
    final cantidad =
        int.tryParse(_cantidadController.text) ?? 0;

    final precio = double.tryParse(
          _precioController.text.replaceAll(',', '.'),
        ) ??
        0;

    return cantidad * precio;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mantenimientoId == null ||
        _repuestoId == null) {
      return;
    }

    final cantidad =
        int.parse(_cantidadController.text);

    final precio = double.parse(
      _precioController.text.replaceAll(',', '.'),
    );

    final notifier = ref.read(
      repuestosMantenimientoAdminProvider.notifier,
    );

    if (widget.initial == null) {
      await notifier.crear(
        mantenimientoId: _mantenimientoId!,
        repuestoId: _repuestoId!,
        cantidad: cantidad,
        precioUnitario: precio,
      );
    } else {
      await notifier.actualizar(
        id: widget.initial!.idRepuestoMantenimiento,
        mantenimientoId: _mantenimientoId!,
        repuestoId: _repuestoId!,
        cantidad: cantidad,
        precioUnitario: precio,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      repuestosMantenimientoAdminProvider,
    );

    final formState = state.formState;
    final saving =
        formState is RepuestoMantenimientoFormSaving;

    if (formState
            is RepuestoMantenimientoFormSuccess &&
        !_cerrando) {
      _cerrando = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formState.message),
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
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                widget.initial == null
                    ? 'Agregar repuesto'
                    : 'Editar repuesto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              DropdownButtonFormField<int>(
                value: _mantenimientoId,
                decoration: const InputDecoration(
                  labelText: 'Mantenimiento *',
                ),
                items: state.mantenimientos.map((item) {
                  return DropdownMenuItem(
                    value: item.idMantenimiento,
                    child: Text(
                      'Mantenimiento #${item.idMantenimiento}',
                    ),
                  );
                }).toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        setState(() {
                          _mantenimientoId = value;
                        });
                      },
                validator: (value) => value == null
                    ? 'Selecciona un mantenimiento'
                    : null,
              ),

              SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: _repuestoId,
                decoration: const InputDecoration(
                  labelText: 'Repuesto *',
                ),
                items: state.repuestos.map((item) {
                  return DropdownMenuItem(
                    value: item.idRepuesto,
                    child: Text(
                      '${item.nombre} (${item.sku})',
                    ),
                  );
                }).toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        setState(() {
                          _repuestoId = value;

                          final seleccionado =
                              state.repuestos.firstWhere(
                            (item) =>
                                item.idRepuesto == value,
                          );

                          _precioController.text =
                              seleccionado.precioVenta
                                  .toStringAsFixed(2);
                        });
                      },
                validator: (value) => value == null
                    ? 'Selecciona un repuesto'
                    : null,
              ),

              SizedBox(height: 14),

              TextFormField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                ),
                validator: (value) {
                  final cantidad =
                      int.tryParse(value ?? '');

                  if (cantidad == null || cantidad <= 0) {
                    return 'Ingresa una cantidad válida';
                  }

                  return null;
                },
              ),

              SizedBox(height: 14),

              TextFormField(
                controller: _precioController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio unitario *',
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final precio = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );

                  if (precio == null || precio <= 0) {
                    return 'Ingresa un precio válido';
                  }

                  return null;
                },
              ),

              SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Subtotal: \$${_subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving ? null : _submit,
                      child: saving
                          ? const CircularProgressIndicator()
                          : Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}