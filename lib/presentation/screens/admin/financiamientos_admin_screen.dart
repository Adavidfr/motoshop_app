// lib/presentation/screens/admin/financiamientos_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/model/venta.dart';
import '../../providers/auth_provider.dart';
import '../../providers/financiamientos_admin_provider.dart';

const _statusFilters = [
  ('',          'Todos'),
  ('activo',    'Activos'),
  ('pagado',    'Pagados'),
  ('vencido',   'Vencidos'),
  ('cancelado', 'Cancelados'),
];

class FinanciamientosAdminScreen extends ConsumerStatefulWidget {
  const FinanciamientosAdminScreen({super.key});

  @override
  ConsumerState<FinanciamientosAdminScreen> createState() => _FinanciamientosAdminScreenState();
}

class _FinanciamientosAdminScreenState extends ConsumerState<FinanciamientosAdminScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 150) {
        ref.read(financiamientosAdminProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state    = ref.watch(financiamientosAdminProvider);
    final tt    = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Stats Header ──────────────────────────────────────
          Container(
            color:   AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financiamientos', style: tt.headlineMedium),
                        Text('${state.total} contratos de financiamiento',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => ref.read(financiamientosAdminProvider.notifier).refresh(),
                      icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Stats Dashboard Grid
                Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        title: 'Monto Total',
                        value: formatPrice(state.statMontoTotal),
                        icon: Icons.account_balance,
                        isHighlight: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _DashboardCard(
                        title: 'Cuota Prom.',
                        value: formatPrice(state.statCuotaPromedio),
                        icon: Icons.payment,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _DashboardCard(
                        title: 'Plazo Prom.',
                        value: '${state.statPlazoPromedio.toStringAsFixed(1)} meses',
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por entidad financiera...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(financiamientosAdminProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  onChanged: (v) {
                    ref.read(financiamientosAdminProvider.notifier).setSearchQuery(v);
                  },
                ),
                SizedBox(height: 10),

                // State Filters
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _statusFilters.map((f) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label:     Text(f.$2, style: TextStyle(fontSize: 12)),
                        selected:  state.statusFilter == f.$1,
                        onSelected:(_) =>
                            ref.read(financiamientosAdminProvider.notifier).setStatusFilter(f.$1),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Contracts List ────────────────────────────────────
          Expanded(
            child: Builder(builder: (_) {
              if (state.isLoading && state.financiamientos.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              if (state.error != null && state.financiamientos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: TextStyle(color: AppColors.error)),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(financiamientosAdminProvider.notifier).refresh(),
                        child:     Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              if (state.financiamientos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📄', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No se encontraron contratos',
                          style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller:      _scrollCtrl,
                padding:         const EdgeInsets.all(12),
                itemCount:       state.financiamientos.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder:(_, __) => SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i >= state.financiamientos.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child:   CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final f = state.financiamientos[i];
                  return _FinanciamientoCard(
                    f: f,
                    isAdmin: isAdmin,
                    onStatus: (newStatus) => ref.read(financiamientosAdminProvider.notifier).changeStatus(f.idFinanciamiento, newStatus),
                    onDelete: () => _confirmDelete(context, f.idFinanciamiento),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Eliminar Financiamiento', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('¿Estás seguro de que deseas eliminar este financiamiento? Esta acción no se puede deshacer.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(financiamientosAdminProvider.notifier).eliminarFinanciamiento(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Financiamiento eliminado exitosamente'),
                    backgroundColor: AppColors.success,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: AppColors.error,
                  ));
                }
              }
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── _FinanciamientoCard Widget ────────────────────────────────
class _FinanciamientoCard extends StatelessWidget {
  final Financiamiento f;
  final bool isAdmin;
  final void Function(String) onStatus;
  final VoidCallback onDelete;

  const _FinanciamientoCard({
    required this.f,
    required this.isAdmin,
    required this.onStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(f.estado);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financiamiento #${f.idFinanciamiento}',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (isAdmin)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            f.entidadFinanciera,
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 8),

          // Core Financial details
          Row(
            children: [
              Expanded(
                child: _DetailItem('Monto Financiado', formatPrice(f.montoFinanciado)),
              ),
              Expanded(
                child: _DetailItem('Cuota Mensual', formatPrice(f.cuotaMensual)),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DetailItem('Tasa Interés', '${f.tasaInteres}%'),
              ),
              Expanded(
                child: _DetailItem('Plazo Contrato', '${f.plazoMeses} meses'),
              ),
            ],
          ),
          SizedBox(height: 6),
          _DetailItem('ID Venta Asociada', '#${f.idVenta}'),

          SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          SizedBox(height: 10),

          // Inline status change dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estado del Plan:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: DropdownButton<String>(
                  value: f.estado,
                  isDense: true,
                  underline: SizedBox.shrink(),
                  dropdownColor: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'activo', child: Text('ACTIVO')),
                    DropdownMenuItem(value: 'pagado', child: Text('PAGADO')),
                    DropdownMenuItem(value: 'vencido', child: Text('VENCIDO')),
                    DropdownMenuItem(value: 'cancelado', child: Text('CANCELADO')),
                  ],
                  onChanged: (val) {
                    if (val != null && val != f.estado) {
                      onStatus(val);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
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

// ── _DetailItem Helper ────────────────────────────────────────
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

// ── _DashboardCard Helper ─────────────────────────────────────
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isHighlight;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isHighlight ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: isHighlight ? AppColors.accent : AppColors.textSecondary, size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                      color: isHighlight ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
