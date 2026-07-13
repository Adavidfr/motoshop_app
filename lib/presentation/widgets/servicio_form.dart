import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/servicio.dart';
import '../../theme/app_colors.dart';
import '../providers/servicios_admin_provider.dart';

Future<void> showServicioForm(
  BuildContext context,
  WidgetRef ref, {
  Servicio? initial,
}) {
  ref.read(serviciosAdminProvider.notifier).resetFormState();

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
      child: ServicioFormSheet(
        initial: initial,
      ),
    ),
  );
}

class ServicioFormSheet extends ConsumerStatefulWidget {
  final Servicio? initial;

  const ServicioFormSheet({
    super.key,
    this.initial,
  });

  @override
  ConsumerState<ServicioFormSheet> createState() {
    return _ServicioFormSheetState();
  }
}

class _ServicioFormSheetState
    extends ConsumerState<ServicioFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _tiempoController = TextEditingController();

  bool _estado = true;
  bool _cerrandoFormulario = false;

  @override
  void initState() {
    super.initState();

    final servicio = widget.initial;

    if (servicio != null) {
      _nombreController.text = servicio.nombre;
      _descripcionController.text =
          servicio.descripcion ?? '';
      _precioController.text =
          servicio.precioBase.toStringAsFixed(2);
      _tiempoController.text =
          servicio.tiempoEstimadoMinutos.toString();
      _estado = servicio.estado;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _tiempoController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    final tiempo = int.tryParse(
      _tiempoController.text.trim(),
    );

    if (precio == null || tiempo == null) {
      return;
    }

    final notifier = ref.read(
      serviciosAdminProvider.notifier,
    );

    if (widget.initial == null) {
      await notifier.crearServicio(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        precioBase: precio,
        tiempoEstimadoMinutos: tiempo,
        estado: _estado,
      );
    } else {
      await notifier.actualizarServicio(
        id: widget.initial!.id,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        precioBase: precio,
        tiempoEstimadoMinutos: tiempo,
        estado: _estado,
      );
    }
  }

  String? _validarNombre(String? value) {
    final nombre = value?.trim() ?? '';

    if (nombre.isEmpty) {
      return 'El nombre es obligatorio';
    }

    if (nombre.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    if (nombre.length > 150) {
      return 'El nombre no puede superar los 150 caracteres';
    }

    return null;
  }

  String? _validarPrecio(String? value) {
    final texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El precio base es obligatorio';
    }

    final precio = double.tryParse(
      texto.replaceAll(',', '.'),
    );

    if (precio == null) {
      return 'Ingresa un precio válido';
    }

    if (precio < 0) {
      return 'El precio no puede ser negativo';
    }

    if (precio > 9999999999.99) {
      return 'El precio supera el valor permitido';
    }

    return null;
  }

  String? _validarTiempo(String? value) {
    final texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El tiempo estimado es obligatorio';
    }

    final tiempo = int.tryParse(texto);

    if (tiempo == null) {
      return 'Ingresa una cantidad válida de minutos';
    }

    if (tiempo <= 0) {
      return 'El tiempo debe ser mayor a 0';
    }

    return null;
  }

  String? _errorBackend(
    ServicioFormState formState,
    String field,
  ) {
    if (formState is ServicioFormError) {
      return formState.fieldError(field);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(
      serviciosAdminProvider.select(
        (state) => state.formState,
      ),
    );

    final isSaving = formState is ServicioFormSaving;
    final isEdit = widget.initial != null;

    if (formState is ServicioFormSuccess &&
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
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          8,
          24,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEdit
                  ? 'Editar servicio'
                  : 'Nuevo servicio',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (isEdit) ...[
              const SizedBox(height: 4),
              Text(
                widget.initial!.nombre,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (formState is ServicioFormError) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  TextFormField(
                    controller: _nombreController,
                    enabled: !isSaving,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: Icon(
                        Icons.build_circle_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'nombre',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarNombre,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descripcionController,
                    enabled: !isSaving,
                    maxLines: 3,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          bottom: 45,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                        ),
                      ),
                      errorText: _errorBackend(
                        formState,
                        'descripcion',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _precioController,
                    enabled: !isSaving,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,10}([.,]\d{0,2})?$'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Precio base *',
                      prefixText: '\$ ',
                      prefixIcon: Icon(
                        Icons.attach_money,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'precio_base',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarPrecio,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _tiempoController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText:
                          'Tiempo estimado en minutos *',
                      prefixIcon: Icon(
                        Icons.schedule_outlined,
                      ),
                      suffixText: 'min',
                      errorText: _errorBackend(
                        formState,
                        'tiempo_estimado_minutos',
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarTiempo,
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Servicio activo',
                                style: TextStyle(
                                  color:
                                      AppColors.textPrimary,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _estado
                                    ? 'Disponible para nuevos mantenimientos'
                                    : 'No estará disponible para nuevas órdenes',
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _estado,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _estado = value;
                                  });
                                },
                          activeColor:
                              AppColors.accent,
                          trackColor:
                              WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(
                                WidgetState.selected,
                              )) {
                                return AppColors.accent
                                    .withValues(alpha: 0.4);
                              }

                              return AppColors.border;
                            },
                          ),
                        ),
                      ],
                    ),
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
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isSaving ? null : _submit,
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
                                      : 'Crear servicio',
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