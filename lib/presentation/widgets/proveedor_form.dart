import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motoshop_app/presentation/providers/proveedor_admin_provider.dart';

import '../../domain/model/proveedor.dart';
import '../../theme/app_colors.dart';


Future<void> showProveedorForm(
  BuildContext context,
  WidgetRef ref, {
  Proveedor? initial,
}) {
  ref.read(proveedoresAdminProvider.notifier).resetFormState();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: ProveedorFormSheet(
        initial: initial,
      ),
    ),
  );
}

class ProveedorFormSheet extends ConsumerStatefulWidget {
  final Proveedor? initial;

  const ProveedorFormSheet({
    super.key,
    this.initial,
  });

  @override
  ConsumerState<ProveedorFormSheet> createState() {
    return _ProveedorFormSheetState();
  }
}

class _ProveedorFormSheetState
    extends ConsumerState<ProveedorFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _contactoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _estado = true;
  bool _cerrandoFormulario = false;

  @override
  void initState() {
    super.initState();

    final proveedor = widget.initial;

    if (proveedor != null) {
      _nombreController.text = proveedor.nombre;
      _contactoController.text = proveedor.contacto ?? '';
      _telefonoController.text = proveedor.telefono ?? '';
      _correoController.text = proveedor.correo ?? '';
      _direccionController.text = proveedor.direccion ?? '';
      _estado = proveedor.estado;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(
      proveedoresAdminProvider.notifier,
    );

    if (widget.initial == null) {
      await notifier.crearProveedor(
        nombre: _nombreController.text,
        contacto: _contactoController.text,
        telefono: _telefonoController.text,
        correo: _correoController.text,
        direccion: _direccionController.text,
        estado: _estado,
      );
    } else {
      await notifier.actualizarProveedor(
        id: widget.initial!.id,
        nombre: _nombreController.text,
        contacto: _contactoController.text,
        telefono: _telefonoController.text,
        correo: _correoController.text,
        direccion: _direccionController.text,
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

    if (nombre.length > 120) {
      return 'El nombre no puede superar los 120 caracteres';
    }

    return null;
  }

  String? _validarContacto(String? value) {
    final contacto = value?.trim() ?? '';

    if (contacto.length > 100) {
      return 'El contacto no puede superar los 100 caracteres';
    }

    return null;
  }

  String? _validarTelefono(String? value) {
    final telefono = value?.trim() ?? '';

    if (telefono.isEmpty) {
      return null;
    }

    if (telefono.length > 20) {
      return 'El teléfono no puede superar los 20 caracteres';
    }

    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(telefono)) {
      return 'Ingresa un número de teléfono válido';
    }

    return null;
  }

  String? _validarCorreo(String? value) {
    final correo = value?.trim() ?? '';

    if (correo.isEmpty) {
      return null;
    }

    final expresion = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!expresion.hasMatch(correo)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  String? _errorBackend(
    ProveedorFormState formState,
    String field,
  ) {
    if (formState is ProveedorFormError) {
      return formState.fieldError(field);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(
      proveedoresAdminProvider.select(
        (state) => state.formState,
      ),
    );

    final isSaving = formState is ProveedorFormSaving;
    final isEdit = widget.initial != null;

    if (formState is ProveedorFormSuccess &&
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
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                  ? 'Editar proveedor'
                  : 'Nuevo proveedor',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (isEdit) ...[
              const SizedBox(height: 4),
              Text(
                widget.initial!.nombre,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (formState is ProveedorFormError) ...[
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
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formState.message,
                        style: const TextStyle(
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
                      prefixIcon: const Icon(
                        Icons.business_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'nombre',
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarNombre,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _contactoController,
                    enabled: !isSaving,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Persona de contacto',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'contacto',
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarContacto,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _telefonoController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'telefono',
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarTelefono,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _correoController,
                    enabled: !isSaving,
                    keyboardType:
                        TextInputType.emailAddress,
                    textCapitalization:
                        TextCapitalization.none,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                      ),
                      errorText: _errorBackend(
                        formState,
                        'correo',
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    validator: _validarCorreo,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _direccionController,
                    enabled: !isSaving,
                    maxLines: 3,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          bottom: 45,
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                        ),
                      ),
                      errorText: _errorBackend(
                        formState,
                        'direccion',
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
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
                                'Proveedor activo',
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
                                    ? 'Disponible para compras y abastecimiento'
                                    : 'No estará disponible para nuevas operaciones',
                                style: const TextStyle(
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
                                      : 'Crear proveedor',
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