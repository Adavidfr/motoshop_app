// lib/presentation/screens/inventory/repuesto_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_providers.dart';
import '../../../domain/model/repuesto.dart';

class RepuestoDetailScreen extends ConsumerWidget {
  final int repuestoId;

  const RepuestoDetailScreen({super.key, required this.repuestoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isStaff = user?.isStaff ?? false;

    final repuestosState = ref.watch(repuestosProvider);
    final repIndex = repuestosState.repuestos.indexWhere((r) => r.idRepuesto == repuestoId);

    if (repIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Repuesto')),
        body: const Center(child: Text('Repuesto no encontrado.')),
      );
    }

    final repuesto = repuestosState.repuestos[repIndex];
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(repuesto.nombre),
        actions: isStaff
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/repuesto-form?id=$repuestoId'),
                  tooltip: 'Editar Repuesto',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref, repuesto),
                  tooltip: 'Eliminar Repuesto',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            Container(
              width: double.infinity,
              height: 250,
              color: AppColors.surface,
              child: repuesto.imagen != null
                  ? Image.network(
                      repuesto.imagen!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Center(
                        child: Icon(Icons.image_not_supported, size: 80, color: AppColors.textSecondary),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.settings_outlined, size: 100, color: AppColors.textSecondary),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repuesto.nombre,
                              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${repuesto.sku}',
                              style: tt.titleMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${repuesto.precioVenta.toStringAsFixed(2)}',
                        style: tt.headlineMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      _buildPill(
                        label: repuesto.stock > 0 ? 'En Stock (${repuesto.stock})' : 'Sin Stock',
                        color: repuesto.stock > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _buildPill(
                        label: repuesto.estado.toUpperCase(),
                        color: repuesto.estado.toLowerCase() == 'activo' ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (repuesto.descripcion != null && repuesto.descripcion!.isNotEmpty) ...[
                    Text(
                      'DESCRIPCIÓN',
                      style: tt.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      repuesto.descripcion!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Specs Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INFORMACIÓN GENERAL',
                          style: tt.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...[
                          ('Nombre', repuesto.nombre),
                          ('SKU', repuesto.sku),
                          ('Costo', '\$${repuesto.costo.toStringAsFixed(2)}'),
                          ('Precio de Venta', '\$${repuesto.precioVenta.toStringAsFixed(2)}'),
                          ('Stock Disponible', '${repuesto.stock} unidades'),
                          ('Estado', repuesto.estado),
                          ('Fecha de Creación', repuesto.fechaRegistro.split('T')[0]),
                        ].asMap().entries.map((entry) {
                          final isLast = entry.key == 6;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.value.$1,
                                        style: const TextStyle(color: AppColors.textSecondary)),
                                    Text(
                                      entry.value.$2,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast) const Divider(height: 1),
                            ],
                          );
                        }),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Repuesto repuesto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Repuesto'),
        content: Text('¿Estás seguro de que deseas eliminar el repuesto "${repuesto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(repuestosProvider.notifier).delete(repuesto.idRepuesto);
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
