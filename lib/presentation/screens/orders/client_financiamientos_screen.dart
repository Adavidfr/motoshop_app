// lib/presentation/screens/orders/client_financiamientos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/orders_client_provider.dart';

class ClientFinanciamientosScreen extends ConsumerWidget {
  const ClientFinanciamientosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financiamientosAsync = ref.watch(clientFinanciamientosProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Financiamientos'),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.refresh(clientFinanciamientosProvider.future),
        child: financiamientosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(err.toString(), style: TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(clientFinanciamientosProvider.future),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: ListView(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💳', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes financiamientos registrados',
                          style: tt.titleMedium?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Los planes de financiamiento se registran al adquirir productos mediante un pedido confirmado.',
                            style: TextStyle(color: AppColors.textFaint, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go('/catalog'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
                          child: const Text('Ver Catálogo'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final f = list[index];
                final statusColor = _getStatusColor(f.estado);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              f.entidadFinanciera,
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              f.estado.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Contrato #${f.idFinanciamiento} · Venta #${f.idVenta}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCell('Monto Financiado', formatPrice(f.montoFinanciado)),
                          ),
                          Expanded(
                            child: _InfoCell('Cuota Mensual', formatPrice(f.cuotaMensual), isHighlight: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCell('Tasa de Interés', '${f.tasaInteres}%'),
                          ),
                          Expanded(
                            child: _InfoCell('Plazo', '${f.plazoMeses} meses'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String state) {
    switch (state.toLowerCase()) {
      case 'activo':
        return AppColors.success;
      case 'pagado':
        return AppColors.info;
      case 'vencido':
        return AppColors.warning;
      case 'cancelado':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoCell(this.label, this.value, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
