// lib/presentation/widgets/marca_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/catalog_providers.dart';
import '../../../domain/model/marca.dart';
import '../../../theme/app_colors.dart';

class MarcaFormDialog extends ConsumerStatefulWidget {
  final Marca? marca;

  const MarcaFormDialog({super.key, this.marca});

  @override
  ConsumerState<MarcaFormDialog> createState() => _MarcaFormDialogState();
}

class _MarcaFormDialogState extends ConsumerState<MarcaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descController;
  late bool _estado;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.marca?.nombre ?? '');
    _descController = TextEditingController(text: widget.marca?.descripcion ?? '');
    _estado = widget.marca?.estado ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(marcasProvider).formState;

    ref.listen<CatalogFormState>(
      marcasProvider.select((s) => s.formState),
      (_, next) {
        if (next is CatalogFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.accent),
          );
          ref.read(marcasProvider.notifier).resetFormState();
          Navigator.of(context).pop(true);
        } else if (next is CatalogFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.error),
          );
          ref.read(marcasProvider.notifier).resetFormState();
        }
      },
    );

    final isSaving = formState is CatalogFormSaving;

    return AlertDialog(
      title: Text(widget.marca == null ? 'Nueva Marca' : 'Editar Marca'),
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
                  hintText: 'Ej. Honda, Yamaha',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Opcional...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (widget.marca != null)
                SwitchListTile(
                  title: const Text('Estado Activo'),
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
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isSaving
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    final nombre = _nombreController.text.trim();
                    final desc = _descController.text.trim();
                    if (widget.marca == null) {
                      ref.read(marcasProvider.notifier).create(nombre, desc.isEmpty ? null : desc);
                    } else {
                      ref
                          .read(marcasProvider.notifier)
                          .update(widget.marca!.idMarca, nombre, desc.isEmpty ? null : desc, _estado);
                    }
                  }
                },
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
