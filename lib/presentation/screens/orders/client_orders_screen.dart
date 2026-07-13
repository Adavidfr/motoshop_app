// lib/presentation/screens/orders/client_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/orders_client_provider.dart';
import '../../widgets/status_badge.dart';

class ClientOrdersScreen extends ConsumerWidget {
  const ClientOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersClientProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          IconButton(
            onPressed: () => ref.read(ordersClientProvider.notifier).load(),
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error!, style: TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(ordersClientProvider.notifier).load(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (state.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛍️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No tienes ningún pedido todavía', style: tt.titleMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go('/catalog'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
                    child: const Text('Explorar catálogo'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => ref.read(ordersClientProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = state.orders[index];
                final dateStr = formatDate(order.createdAt.toIso8601String());

                return GestureDetector(
                  onTap: () => context.push('/orders/${order.id}'),
                  child: Container(
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
                            Text(
                              'Pedido #${order.id}',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            StatusBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(dateStr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: order.items.take(2).map((item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.quantity}x ${item.productName}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          )).toList(),
                        ),
                        if (order.items.length > 2) ...[
                          const SizedBox(height: 4),
                          Text('+${order.items.length - 2} productos más', style: TextStyle(color: AppColors.textFaint, fontSize: 11)),
                        ],
                        const SizedBox(height: 12),
                        Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${order.numItems} producto${order.numItems != 1 ? "s" : ""}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            Text(
                              formatPrice(order.total),
                              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
