// lib/presentation/screens/admin/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/kpi_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return switch (state) {
      DashboardLoading() => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      DashboardError(message: final msg) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(msg, style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(dashboardProvider.notifier).load(),
                child:     const Text('Reintentar'),
              ),
            ],
          ),
        ),
      DashboardSuccess(data: final d, loadedAt: final loadedAt) =>
          _DashboardContent(data: d, loadedAt: loadedAt),
    };
  }
}

class _DashboardContent extends ConsumerWidget {
  final DashboardData data;
  final DateTime      loadedAt;
  const _DashboardContent({required this.data, required this.loadedAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFmt = '${loadedAt.hour.toString().padLeft(2,'0')}:'
                    '${loadedAt.minute.toString().padLeft(2,'0')}:'
                    '${loadedAt.second.toString().padLeft(2,'0')}';

    return RefreshIndicator(
      color:       AppColors.accent,
      onRefresh:   () => ref.read(dashboardProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Header ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text('Actualizado: $timeFmt',
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                ],
              ),
              IconButton(
                icon:      const Icon(Icons.refresh_rounded, color: AppColors.accent),
                onPressed: () => ref.read(dashboardProvider.notifier).load(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── KPIs fila 1 ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title:    'Productos activos',
                  value:    '${data.totalActiveProducts}',
                  icon:     Icons.inventory_2_outlined,
                  color:    AppColors.accent,
                  onTap:    () => context.go('/admin/catalog'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  title:    'Usuarios registrados',
                  value:    '${data.totalUsers}',
                  subtitle: '${data.activeUsers} activos',
                  icon:     Icons.people_outline,
                  color:    AppColors.info,
                  onTap:    () => context.go('/admin/users'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── KPIs fila 2 ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title:    'Ventas totales',
                  value:    '${data.totalOrders}',
                  subtitle: data.pendingOrders > 0
                      ? '${data.pendingOrders} pendientes' : null,
                  icon:     Icons.shopping_bag_outlined,
                  color:    AppColors.success,
                  hasAlert: data.pendingOrders > 0,
                  onTap:    () => context.go('/admin/ventas'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  title:  'Ingresos totales',
                  value:  formatPrice(data.totalRevenue),
                  icon:   Icons.trending_up_rounded,
                  color:  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Pedidos por estado — barras ───────────────────
          if (data.ordersByStatus.isNotEmpty) ...[
            _SectionCard(
              title:     'Ventas por estado',
              actionLabel: 'Ver todas',
              onAction:  () => context.go('/admin/ventas'),
              child: Column(
                children: data.ordersByStatus.entries.map((entry) {
                  final statusName = entry.key;
                  final count   = entry.value;
                  final total   = data.totalOrders.clamp(1, 999999);
                  final pct     = (count / total).clamp(0.02, 1.0);
                  
                  // Asignar colores según el estado aproximado
                  Color color = AppColors.info;
                  if (statusName.toLowerCase() == 'completada') color = AppColors.success;
                  if (statusName.toLowerCase() == 'cancelada') color = AppColors.error;
                  if (statusName.toLowerCase() == 'pendiente') color = AppColors.warning;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(statusName.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12,
                                )),
                            Text(
                              '$count',
                              style: TextStyle(
                                color: color, fontWeight: FontWeight.bold, fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value:     pct,
                            minHeight: 7,
                            backgroundColor:  AppColors.surface2,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Acciones rápidas ──────────────────────────────
          _SectionCard(
            title: '⚡ Acciones rápidas',
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ('Catálogo',   AppColors.info,     '/admin/catalog'),
                ('Ventas',     AppColors.success,  '/admin/ventas'),
                ('Usuarios',   AppColors.warning,  '/admin/users'),
                ('Inventario', AppColors.accent,   '/inventory'),
              ].map((item) => GestureDetector(
                onTap: () => context.go(item.$3 as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:        (item.$2 as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: (item.$2 as Color).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item.$1 as String,
                    style: TextStyle(
                      color:      item.$2 as Color,
                      fontWeight: FontWeight.bold,
                      fontSize:   13,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String       title;
  final IconData?    titleIcon;
  final Color?       titleColor;
  final String?      actionLabel;
  final VoidCallback? onAction;
  final Widget       child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.titleIcon,
    this.titleColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, color: titleColor ?? AppColors.textPrimary, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color:      titleColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  '$actionLabel →',
                  style: const TextStyle(
                    color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
