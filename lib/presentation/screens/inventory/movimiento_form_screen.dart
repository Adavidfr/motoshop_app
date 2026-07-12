// lib/presentation/screens/inventory/movimiento_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../providers/inventory_providers.dart';
import '../../providers/catalog_providers.dart';

class MovimientoFormScreen extends ConsumerStatefulWidget {
  const MovimientoFormScreen({super.key});

  @override
  ConsumerState<MovimientoFormScreen> createState() => _MovimientoFormScreenState();
}

class _MovimientoFormScreenState extends ConsumerState<MovimientoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cantidadCtrl;
  late TextEditingController _descCtrl;

  String _tipoMovimiento = 'entrada';
  String _tipoItem = 'repuesto'; // 'repuesto' o 'moto'

  int? _selectedMotoId;
  int? _selectedRepuestoId;

  @override
  void initState() {
    super.initState();
    _cantidadCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motosState = ref.watch(motosProvider);
    final repuestosState = ref.watch(repuestosProvider);
    final movimientosState = ref.watch(movimientosProvider);

    ref.listen<InventoryFormState>(
      movimientosProvider.select((s) => s.formState),
      (_, next) {
        if (next is InventoryFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.accent),
          );
          ref.read(movimientosProvider.notifier).resetFormState();
          ref.read(movimientosProvider.notifier).loadFirstPage();
          context.pop();
        } else if (next is InventoryFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.error),
          );
          ref.read(movimientosProvider.notifier).resetFormState();
        }
      },
    );

    final isSaving = movimientosState.formState is InventoryFormSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de Movimiento Segmented Button
              const Text('Tipo de Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'entrada',
                    label: Text('Entrada'),
                    icon: Icon(Icons.arrow_downward, color: Colors.green),
                  ),
                  ButtonSegment(
                    value: 'salida',
                    label: Text('Salida'),
                    icon: Icon(Icons.arrow_upward, color: Colors.red),
                  ),
                ],
                selected: {_tipoMovimiento},
                onSelectionChanged: (val) {
                  setState(() => _tipoMovimiento = val.first);
                },
              ),
              const SizedBox(height: 24),

              // Tipo de Item Segmented Button
              const Text('Tipo de Artículo Afectado', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'repuesto',
                    label: Text('Repuesto'),
                    icon: Icon(Icons.build_outlined),
                  ),
                  ButtonSegment(
                    value: 'moto',
                    label: Text('Motocicleta'),
                    icon: Icon(Icons.motorcycle_outlined),
                  ),
                ],
                selected: {_tipoItem},
                onSelectionChanged: (val) {
                  setState(() {
                    _tipoItem = val.first;
                    _selectedMotoId = null;
                    _selectedRepuestoId = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Selection Dropdowns
              if (_tipoItem == 'moto') ...[
                DropdownButtonFormField<int>(
                  value: _selectedMotoId,
                  decoration: const InputDecoration(labelText: 'Seleccionar Motocicleta'),
                  items: motosState.motos
                      .map((m) => DropdownMenuItem(
                            value: m.idMoto,
                            child: Text('${m.marca.nombre} ${m.modelo} (${m.color})'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedMotoId = val),
                  validator: (val) => val == null ? 'Selecciona una motocicleta' : null,
                ),
              ] else ...[
                DropdownButtonFormField<int>(
                  value: _selectedRepuestoId,
                  decoration: const InputDecoration(labelText: 'Seleccionar Repuesto'),
                  items: repuestosState.repuestos
                      .map((r) => DropdownMenuItem(
                            value: r.idRepuesto,
                            child: Text('${r.nombre} (SKU: ${r.sku})'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedRepuestoId = val),
                  validator: (val) => val == null ? 'Selecciona un repuesto' : null,
                ),
              ],
              const SizedBox(height: 16),

              // Cantidad Input
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(labelText: 'Cantidad de Unidades'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'El número es obligatorio';
                  final parsed = int.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Cantidad debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripcion Input
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Detalle o Motivo', hintText: 'Ej. Compra de inventario local, venta...'),
                maxLines: 3,
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
                      : const Text('Registrar Movimiento'),
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

    final cantidad = int.parse(_cantidadCtrl.text.trim());
    final descripcion = _descCtrl.text.trim();

    ref.read(movimientosProvider.notifier).registerMovement(
          tipoMovimiento: _tipoMovimiento,
          cantidad: cantidad,
          descripcion: descripcion.isEmpty ? null : descripcion,
          motoId: _tipoItem == 'moto' ? _selectedMotoId : null,
          repuestoId: _tipoItem == 'repuesto' ? _selectedRepuestoId : null,
        );
  }
}
