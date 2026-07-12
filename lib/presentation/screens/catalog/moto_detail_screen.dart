// lib/presentation/screens/catalog/moto_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../../domain/model/moto.dart';

class MotoDetailScreen extends ConsumerWidget {
  final int motoId;

  const MotoDetailScreen({super.key, required this.motoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final isVendedor = user?.role == 'vendedor';
    final canEdit = isAdmin || isVendedor || user?.isStaff == true;
    final canDelete = isAdmin;

    // Retrieve moto from provider list
    final motosState = ref.watch(motosProvider);
    final motoIndex = motosState.motos.indexWhere((m) => m.idMoto == motoId);

    if (motoIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Moto')),
        body: const Center(child: Text('Motocicleta no encontrada.')),
      );
    }

    final moto = motosState.motos[motoIndex];
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${moto.marca.nombre} ${moto.modelo}'),
        actions: canEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/moto-form?id=$motoId'),
                  tooltip: 'Editar Motocicleta',
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _confirmDelete(context, ref, moto),
                    tooltip: 'Eliminar Motocicleta',
                  ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big image header
            Container(
              width: double.infinity,
              height: 250,
              color: AppColors.surface,
              child: moto.imagen != null
                  ? Image.network(
                      moto.imagen!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Center(
                        child: Icon(Icons.image_not_supported, size: 80, color: AppColors.textSecondary),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.motorcycle, size: 100, color: AppColors.textSecondary),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${moto.marca.nombre} ${moto.modelo}',
                              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              moto.categoria.nombre,
                              style: tt.titleMedium?.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${moto.precio.toStringAsFixed(2)}',
                        style: tt.headlineMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stock & Status pills
                  Row(
                    children: [
                      _buildPill(
                        label: moto.stock > 0 ? 'Disponible (${moto.stock})' : 'Agotado',
                        color: moto.stock > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _buildPill(
                        label: moto.estado.toUpperCase(),
                        color: moto.estado.toLowerCase() == 'activo' ||
                                moto.estado.toLowerCase() == 'disponible'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Detail specifications card
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
                          'ESPECIFICACIONES TÉCNICAS',
                          style: tt.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...[
                          ('Marca', moto.marca.nombre),
                          ('Modelo', moto.modelo),
                          ('Categoría', moto.categoria.nombre),
                          ('Año de Fabricación', '${moto.anio}'),
                          ('Cilindraje (Motor)', '${moto.cilindraje} cc'),
                          ('Color', moto.color),
                          ('Precio de Lista', '\$${moto.precio.toStringAsFixed(2)}'),
                          ('Fecha de Registro', moto.fechaRegistro.split('T')[0]),
                        ].asMap().entries.map((entry) {
                          final isLast = entry.key == 7;
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
                  ),
                ],
              ),
            ),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Moto moto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Motocicleta'),
        content: Text('¿Estás seguro de que deseas eliminar la motocicleta "${moto.marca.nombre} ${moto.modelo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(motosProvider.notifier).delete(moto.idMoto);
              Navigator.of(context).pop(); // pop dialog
              context.pop(); // pop details screen
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
