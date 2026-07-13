// lib/presentation/screens/admin/ventas_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/model/venta.dart';
import '../../providers/ventas_admin_provider.dart';

const _statusFilters = [
  ('',            'Todos'),
  ('completada',  'Completadas'),
  ('pendiente',   'Pendientes'),
  ('cancelada',   'Canceladas'),
];

class VentasAdminScreen extends ConsumerStatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  ConsumerState<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends ConsumerState<VentasAdminScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 150) {
        ref.read(ventasAdminProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ventasAdminProvider);
    final tt    = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Stats Header ──────────────────────────────────────
          Container(
            color:   AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ventas y Facturación', style: tt.headlineMedium),
                        Text('Registro formal de transacciones',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => ref.read(ventasAdminProvider.notifier).refresh(),
                      icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Ventas',
                        value: '${state.statTotalVentas}',
                        icon: Icons.assignment_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Ingresos',
                        value: formatPrice(state.statTotalIngresos),
                        icon: Icons.monetization_on_outlined,
                        isHighlight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _statusFilters.map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label:     Text(f.$2),
                        selected:  state.statusFilter == f.$1,
                        onSelected:(_) =>
                            ref.read(ventasAdminProvider.notifier).setStatusFilter(f.$1),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Sales Listing ─────────────────────────────────────
          Expanded(
            child: Builder(builder: (_) {
              if (state.isLoading && state.ventas.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              if (state.error != null && state.ventas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(ventasAdminProvider.notifier).refresh(),
                        child:     const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              if (state.ventas.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('💸', style: TextStyle(fontSize: 52)),
                      SizedBox(height: 12),
                      Text('Sin transacciones de ventas',
                          style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller:      _scrollCtrl,
                padding:         const EdgeInsets.all(16),
                itemCount:       state.ventas.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder:(_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i >= state.ventas.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child:   CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final venta = state.ventas[i];
                  return _VentaCard(
                    venta: venta,
                    onTap: () => _showVentaDetailsDialog(context, venta),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Show Venta Details and Financing Panel ──────────────────
  void _showVentaDetailsDialog(BuildContext context, Venta venta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Detalle de Venta #${venta.idVenta}',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _DialogRow('ID Pedido:', '#${venta.idPedido}'),
              _DialogRow('Cliente:', venta.usernameCliente),
              _DialogRow('Vendedor:', venta.usernameVendedor),
              _DialogRow('Total Venta:', formatPrice(venta.totalVenta)),
              _DialogRow('Estado:', venta.estado.toUpperCase()),
              _DialogRow('Fecha:', formatDate(venta.fechaVenta.toIso8601String())),
              Divider(height: 24, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Financiamientos',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddFinancingDialog(context, venta);
                    },
                    icon: Icon(Icons.add, size: 16),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (venta.financiamientos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No hay financiamientos registrados para esta venta.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                )
              else
                ...venta.financiamientos.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(f.entidadFinanciera,
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: f.estado == 'activo' ? Colors.green.withValues(alpha: 0.15) : AppColors.textFaint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(f.estado.toUpperCase(),
                                style: TextStyle(color: f.estado == 'activo' ? Colors.green : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monto: ${formatPrice(f.montoFinanciado)}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('Plazo: ${f.plazoMeses} meses', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tasa: ${f.tasaInteres}%', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('Cuota: ${formatPrice(f.cuotaMensual)}', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ── Dialog to Add Financing ──────────────────────────────────
  void _showAddFinancingDialog(BuildContext context, Venta venta) {
    final entidadCtrl = TextEditingController();
    final montoCtrl   = TextEditingController(text: venta.totalVenta.toString());
    final tasaCtrl    = TextEditingController(text: '12.0');
    final plazoCtrl   = TextEditingController(text: '12');
    final cuotaCtrl   = TextEditingController();
    String estadoVal  = 'activo';

    void calculateCuota() {
      final double monto = double.tryParse(montoCtrl.text) ?? 0.0;
      final double tasa  = double.tryParse(tasaCtrl.text) ?? 0.0;
      final int plazo    = int.tryParse(plazoCtrl.text) ?? 0;
      if (monto > 0 && plazo > 0) {
        // Simple monthly payment calculation (Monto * (1 + Tasa / 100)) / Plazo
        final double cuota = (monto * (1 + tasa / 100)) / plazo;
        cuotaCtrl.text = cuota.toStringAsFixed(2);
      }
    }

    calculateCuota(); // Initial calc

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Nuevo Financiamiento (Venta #${venta.idVenta})',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: entidadCtrl,
                decoration: const InputDecoration(labelText: 'Entidad Financiera', hintText: 'Ej. Banco Pichincha'),
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto a Financiar'),
                style: TextStyle(color: AppColors.textPrimary),
                onChanged: (_) => calculateCuota(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tasaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Tasa Interés (%)'),
                      style: TextStyle(color: AppColors.textPrimary),
                      onChanged: (_) => calculateCuota(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: plazoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Plazo (Meses)'),
                      style: TextStyle(color: AppColors.textPrimary),
                      onChanged: (_) => calculateCuota(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cuotaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cuota Mensual Est. (\$)'),
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: estadoVal,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Estado'),
                style: TextStyle(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                  DropdownMenuItem(value: 'vencido', child: Text('Vencido')),
                  DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                ],
                onChanged: (v) {
                  if (v != null) estadoVal = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
            onPressed: () async {
              if (entidadCtrl.text.isEmpty ||
                  montoCtrl.text.isEmpty ||
                  tasaCtrl.text.isEmpty ||
                  plazoCtrl.text.isEmpty ||
                  cuotaCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Por favor completa todos los campos'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }
              try {
                await ref.read(ventasAdminProvider.notifier).registrarFinanciamiento(
                  venta.idVenta,
                  entidad: entidadCtrl.text,
                  monto: double.parse(montoCtrl.text),
                  tasa: double.parse(tasaCtrl.text),
                  plazo: int.parse(plazoCtrl.text),
                  cuota: double.parse(cuotaCtrl.text),
                  estado: estadoVal,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Financiamiento agregado exitosamente'),
                    backgroundColor: AppColors.success,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// ── VentaCard Widget ──────────────────────────────────────────
class _VentaCard extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;

  const _VentaCard({required this.venta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Venta #${venta.idVenta}',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Pedido #${venta.idPedido} · ${venta.usernameCliente}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: venta.estado == 'completada' ? Colors.green.withValues(alpha: 0.15) : AppColors.surface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    venta.estado.toUpperCase(),
                    style: TextStyle(
                      color: venta.estado == 'completada' ? Colors.green : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${venta.numFinanciamientos} plan${venta.numFinanciamientos != 1 ? "es" : ""} fin.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                Text(
                  formatPrice(venta.totalVenta),
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── StatCard Widget ───────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isHighlight;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighlight ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isHighlight ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface,
            child: Icon(icon, color: isHighlight ? AppColors.accent : AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      color: isHighlight ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small Row Helper for Dialog ──────────────────────────────
class _DialogRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
