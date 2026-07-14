// lib/presentation/widgets/categoria_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motoshop_app/presentation/providers/catalog_providers.dart';
import '../../../domain/model/categoria_moto.dart';
import '../../../theme/app_colors.dart';

class CategoriaFormDialog extends ConsumerStatefulWidget {
  final CategoriaMoto? categoria;

  const CategoriaFormDialog({super.key, this.categoria});

  @override
  ConsumerState<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends ConsumerState<CategoriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descController;
  late bool _estado;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria?.nombre ?? '');
    _descController = TextEditingController(text: widget.categoria?.descripcion ?? '');
    _estado = widget.categoria?.estado ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(categoriasProvider).formState;

    ref.listen<CatalogFormState>(
      categoriasProvider.select((s) => s.formState),
      (_, next) {
        if (next is CatalogFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.accent),
          );
          ref.read(categoriasProvider.notifier).resetFormState();
          Navigator.of(context).pop(true);
        } else if (next is CatalogFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.error),
          );
          ref.read(categoriasProvider.notifier).resetFormState();
        }
      },
    );

    final isSaving = formState is CatalogFormSaving;

    return AlertDialog(
      title: Text(widget.categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Scooter, Deportiva, Enduro',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Opcional...',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              if (widget.categoria != null)
                SwitchListTile(
                  title: Text('Estado Activo'),
                  value: _estado,
                  activeColor: AppColors.accent,
                  onChanged: (val) => setState(() => _estado = val),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isSaving
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    final nombre = _nombreController.text.trim();
                    final desc = _descController.text.trim();
                    if (widget.categoria == null) {
                      ref.read(categoriasProvider.notifier).create(nombre, desc.isEmpty ? null : desc);
                    } else {
                      ref.read(categoriasProvider.notifier).update(
                          widget.categoria!.idCategoria, nombre, desc.isEmpty ? null : desc, _estado);
                    }
                  }
                },
          child: isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Guardar'),
        ),
      ],
    );
  }
}
