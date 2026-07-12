// lib/presentation/screens/catalog/moto_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../providers/catalog_providers.dart';
import '../../../domain/model/moto.dart';

class MotoFormScreen extends ConsumerStatefulWidget {
  final int? motoId;

  const MotoFormScreen({super.key, this.motoId});

  @override
  ConsumerState<MotoFormScreen> createState() => _MotoFormScreenState();
}

class _MotoFormScreenState extends ConsumerState<MotoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _modeloCtrl;
  late TextEditingController _anioCtrl;
  late TextEditingController _cilindrajeCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _stockCtrl;

  int? _selectedMarcaId;
  int? _selectedCategoriaId;
  late String _selectedEstado;
  File? _selectedImageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    Moto? editingMoto;
    if (widget.motoId != null) {
      final motosState = ref.read(motosProvider);
      final idx = motosState.motos.indexWhere((m) => m.idMoto == widget.motoId);
      if (idx != -1) {
        editingMoto = motosState.motos[idx];
      }
    }

    _modeloCtrl = TextEditingController(text: editingMoto?.modelo ?? '');
    _anioCtrl = TextEditingController(text: editingMoto?.anio.toString() ?? '');
    _cilindrajeCtrl = TextEditingController(text: editingMoto?.cilindraje.toString() ?? '');
    _colorCtrl = TextEditingController(text: editingMoto?.color ?? '');
    _precioCtrl = TextEditingController(text: editingMoto?.precio.toString() ?? '');
    _stockCtrl = TextEditingController(text: editingMoto?.stock.toString() ?? '');

    _selectedMarcaId = editingMoto?.marca.idMarca;
    _selectedCategoriaId = editingMoto?.categoria.idCategoria;
    _selectedEstado = editingMoto?.estado ?? 'activo';
    _existingImageUrl = editingMoto?.imagen;
  }

  @override
  void dispose() {
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _cilindrajeCtrl.dispose();
    _colorCtrl.dispose();
    _precioCtrl.dispose();
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
    final marcasState = ref.watch(marcasProvider);
    final categoriasState = ref.watch(categoriasProvider);
    final motosState = ref.watch(motosProvider);

    ref.listen<CatalogFormState>(
      motosProvider.select((s) => s.formState),
      (_, next) {
        if (next is CatalogFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.accent),
          );
          ref.read(motosProvider.notifier).resetFormState();
          ref.read(motosProvider.notifier).loadFirstPage();
          context.pop();
        } else if (next is CatalogFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.error),
          );
          ref.read(motosProvider.notifier).resetFormState();
        }
      },
    );

    final isSaving = motosState.formState is CatalogFormSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.motoId == null ? 'Registrar Motocicleta' : 'Editar Motocicleta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Area
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
                            : const Column(
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
              const SizedBox(height: 24),

              // Marca Dropdown
              DropdownButtonFormField<int>(
                value: _selectedMarcaId,
                decoration: const InputDecoration(labelText: 'Marca'),
                items: marcasState.marcas
                    .map((m) => DropdownMenuItem(value: m.idMarca, child: Text(m.nombre)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMarcaId = val),
                validator: (val) => val == null ? 'Selecciona una marca' : null,
              ),
              const SizedBox(height: 16),

              // Categoria Dropdown
              DropdownButtonFormField<int>(
                value: _selectedCategoriaId,
                decoration: const InputDecoration(labelText: 'Categoría de Moto'),
                items: categoriasState.categorias
                    .map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoriaId = val),
                validator: (val) => val == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),

              // Modelo Input
              TextFormField(
                controller: _modeloCtrl,
                decoration: const InputDecoration(labelText: 'Modelo', hintText: 'Ej. CBR 250R'),
                validator: (val) => val == null || val.trim().isEmpty ? 'El modelo es obligatorio' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Anio Input
                  Expanded(
                    child: TextFormField(
                      controller: _anioCtrl,
                      decoration: const InputDecoration(labelText: 'Año', hintText: 'Ej. 2024'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        final parsed = int.tryParse(val);
                        if (parsed == null || parsed < 1900 || parsed > 2100) return 'Año inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Cilindraje Input
                  Expanded(
                    child: TextFormField(
                      controller: _cilindrajeCtrl,
                      decoration: const InputDecoration(labelText: 'Cilindraje (cc)', hintText: 'Ej. 250'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        final parsed = int.tryParse(val);
                        if (parsed == null || parsed <= 0) return 'Cilindraje inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Color Input
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(labelText: 'Color', hintText: 'Ej. Negro, Rojo metálico'),
                validator: (val) => val == null || val.trim().isEmpty ? 'El color es obligatorio' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Precio Input
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        final parsed = double.tryParse(val);
                        if (parsed == null || parsed <= 0) return 'Precio inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Stock Input
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        final parsed = int.tryParse(val);
                        if (parsed == null || parsed < 0) return 'Stock inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Estado Dropdown
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                  DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                  DropdownMenuItem(value: 'no disponible', child: Text('No Disponible')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedEstado = val);
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _onSubmit,
                  child: isSaving
                      ? const CircularProgressIndicator()
                      : Text(widget.motoId == null ? 'Registrar Motocicleta' : 'Guardar Cambios'),
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

    final modelo = _modeloCtrl.text.trim();
    final anio = int.parse(_anioCtrl.text.trim());
    final cilindraje = int.parse(_cilindrajeCtrl.text.trim());
    final color = _colorCtrl.text.trim();
    final precio = double.parse(_precioCtrl.text.trim());
    final stock = int.parse(_stockCtrl.text.trim());

    if (widget.motoId == null) {
      ref.read(motosProvider.notifier).create(
            categoriaId: _selectedCategoriaId!,
            marcaId: _selectedMarcaId!,
            modelo: modelo,
            anio: anio,
            cilindraje: cilindraje,
            color: color,
            precio: precio,
            stock: stock,
            estado: _selectedEstado,
            imagen: _selectedImageFile,
          );
    } else {
      ref.read(motosProvider.notifier).update(
            widget.motoId!,
            categoriaId: _selectedCategoriaId,
            marcaId: _selectedMarcaId,
            modelo: modelo,
            anio: anio,
            cilindraje: cilindraje,
            color: color,
            precio: precio,
            stock: stock,
            estado: _selectedEstado,
            imagen: _selectedImageFile,
          );
    }
  }
}
