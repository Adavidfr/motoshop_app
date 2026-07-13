// lib/presentation/screens/inventory/repuesto_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../providers/inventory_providers.dart';
import '../../../domain/model/repuesto.dart';

class RepuestoFormScreen extends ConsumerStatefulWidget {
  final int? repuestoId;

  const RepuestoFormScreen({super.key, this.repuestoId});

  @override
  ConsumerState<RepuestoFormScreen> createState() => _RepuestoFormScreenState();
}

class _RepuestoFormScreenState extends ConsumerState<RepuestoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _costoCtrl;
  late TextEditingController _precioVentaCtrl;
  late TextEditingController _stockCtrl;

  late String _selectedEstado;
  File? _selectedImageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    Repuesto? editingRepuesto;
    if (widget.repuestoId != null) {
      final repState = ref.read(repuestosProvider);
      final idx = repState.repuestos.indexWhere((r) => r.idRepuesto == widget.repuestoId);
      if (idx != -1) {
        editingRepuesto = repState.repuestos[idx];
      }
    }

    _nombreCtrl = TextEditingController(text: editingRepuesto?.nombre ?? '');
    _descCtrl = TextEditingController(text: editingRepuesto?.descripcion ?? '');
    _skuCtrl = TextEditingController(text: editingRepuesto?.sku ?? '');
    _costoCtrl = TextEditingController(text: editingRepuesto?.costo.toString() ?? '');
    _precioVentaCtrl = TextEditingController(text: editingRepuesto?.precioVenta.toString() ?? '');
    _stockCtrl = TextEditingController(text: editingRepuesto?.stock.toString() ?? '');

    final rawEstado = editingRepuesto?.estado.toLowerCase() ?? 'activo';
    _selectedEstado = ['activo', 'inactivo'].contains(rawEstado)
        ? rawEstado
        : 'activo';
        
    _existingImageUrl = editingRepuesto?.imagen;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _skuCtrl.dispose();
    _costoCtrl.dispose();
    _precioVentaCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImageFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repuestosState = ref.watch(repuestosProvider);

    ref.listen<InventoryFormState>(
      repuestosProvider.select((s) => s.formState),
      (_, next) {
        if (next is InventoryFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.accent),
          );
          ref.read(repuestosProvider.notifier).resetFormState();
          ref.read(repuestosProvider.notifier).loadFirstPage();
          context.pop();
        } else if (next is InventoryFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.error),
          );
          ref.read(repuestosProvider.notifier).resetFormState();
        }
      },
    );

    final isSaving = repuestosState.formState is InventoryFormSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repuestoId == null ? 'Registrar Repuesto' : 'Editar Repuesto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _selectedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.textSecondary),
                                  SizedBox(height: 8),
                                  Text('Añadir Foto', style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Nombre Input
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Repuesto', hintText: 'Ej. Kit de arrastre'),
                validator: (val) => val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              SizedBox(height: 16),

              // SKU Input
              TextFormField(
                controller: _skuCtrl,
                decoration: const InputDecoration(labelText: 'SKU (Código único)', hintText: 'Ej. HON-CBR-250-KIT'),
                validator: (val) => val == null || val.trim().isEmpty ? 'El SKU es obligatorio' : null,
              ),
              SizedBox(height: 16),

              // Descripcion Input
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  // Costo Input
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      decoration: const InputDecoration(labelText: 'Costo de Compra', prefixText: '\$'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        final parsed = double.tryParse(val);
                        if (parsed == null || parsed <= 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  // Precio Venta Input
                  Expanded(
                    child: TextFormField(
                      controller: _precioVentaCtrl,
                      decoration: const InputDecoration(labelText: 'Precio de Venta', prefixText: '\$'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        final parsed = double.tryParse(val);
                        if (parsed == null || parsed <= 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Stock Input (Only available on create; on edit, inventory movements must be used to adjust stock)
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock Inicial'),
                keyboardType: TextInputType.number,
                enabled: widget.repuestoId == null,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  final parsed = int.tryParse(val);
                  if (parsed == null || parsed < 0) return 'Stock inválido';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Estado Dropdown
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedEstado = val);
                },
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _onSubmit,
                  child: isSaving
                      ? const CircularProgressIndicator()
                      : Text(widget.repuestoId == null ? 'Registrar Repuesto' : 'Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreCtrl.text.trim();
    final sku = _skuCtrl.text.trim();
    final descripcion = _descCtrl.text.trim();
    final costo = double.parse(_costoCtrl.text.trim());
    final precioVenta = double.parse(_precioVentaCtrl.text.trim());
    final stock = int.parse(_stockCtrl.text.trim());

    if (widget.repuestoId == null) {
      ref.read(repuestosProvider.notifier).create(
            nombre: nombre,
            sku: sku,
            descripcion: descripcion.isEmpty ? null : descripcion,
            costo: costo,
            precioVenta: precioVenta,
            stock: stock,
            estado: _selectedEstado,
            imagen: _selectedImageFile,
          );
    } else {
      ref.read(repuestosProvider.notifier).update(
            widget.repuestoId!,
            nombre: nombre,
            sku: sku,
            descripcion: descripcion.isEmpty ? null : descripcion,
            costo: costo,
            precioVenta: precioVenta,
            estado: _selectedEstado,
            imagen: _selectedImageFile,
          );
    }
  }
}
