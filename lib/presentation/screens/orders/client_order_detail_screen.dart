// lib/presentation/screens/orders/client_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/model/order.dart';
import '../../providers/orders_client_provider.dart';
import '../../widgets/status_badge.dart';

class ClientOrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const ClientOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderClientDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detalle de Pedido #$orderId'),
      ),
      body: orderAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(err.toString(), style: TextStyle(color: AppColors.error)),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text('Volver'),
              ),
            ],
          ),
        ),
        data: (order) => _DetailContent(order: order),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Order order;
  const _DetailContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final taxAmount  = order.total - order.total / 1.15;
    final subtotal   = order.total - taxAmount;
    final dateStr    = formatDateTime(order.createdAt.toIso8601String());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary card
          _Card(
            title: 'Información general',
            child: Column(
              children: [
                _InfoRow('Número de pedido', '#${order.id}'),
                _InfoRow('Fecha', dateStr),
                _InfoRow('Cantidad total', '${order.numItems} items'),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estado del pedido', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    StatusBadge(status: order.status),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Items card
          _Card(
            title: 'Productos en tu pedido',
            child: Column(
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('📦', style: TextStyle(fontSize: 20))),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          Text('${formatPrice(item.unitPrice)} × ${item.quantity} ud.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(formatPrice(item.subtotal), style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            ),
          ),
          SizedBox(height: 14),

          // Financial summary card
          _Card(
            title: 'Resumen de pago',
            child: Column(
              children: [
                _TotalRow('Subtotal (sin IVA)', subtotal, false),
                SizedBox(height: 6),
                _TotalRow('IVA (15%)', taxAmount, false),
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                _TotalRow('Total pagado', order.total, true),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isFinal;
  const _TotalRow(this.label, this.value, this.isFinal);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: isFinal ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: isFinal ? 15 : 13,
          fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        formatPrice(value),
        style: TextStyle(
          color: isFinal ? AppColors.accent : AppColors.textPrimary,
          fontSize: isFinal ? 17 : 13,
          fontWeight: isFinal ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}
