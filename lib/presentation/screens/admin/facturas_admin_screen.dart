// lib/presentation/screens/admin/facturas_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/factura.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/facturas_admin_provider.dart';
import '../../widgets/factura_form.dart';

class FacturasAdminScreen extends ConsumerStatefulWidget {
  const FacturasAdminScreen({super.key});

  @override
  ConsumerState<FacturasAdminScreen> createState() =>
      _FacturasAdminScreenState();
}

class _FacturasAdminScreenState extends ConsumerState<FacturasAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(facturasAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();
    await ref.read(facturasAdminProvider.notifier).setSearch('');
    if (mounted) setState(() {});
  }

  Future<void> _confirmarEliminar(BuildContext context, Factura factura) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Eliminar factura',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Eliminar la factura #${factura.numeroFactura}?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref
          .read(facturasAdminProvider.notifier)
          .eliminarFactura(factura.idFactura);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(facturasAdminProvider);
    final notifier = ref.read(facturasAdminProvider.notifier);
    debugPrint('FacturasAdminScreen Build: isLoading=${state.isLoading}, error=${state.error}, items=${state.facturas.length}');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Facturas',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.total} factura${state.total == 1 ? '' : 's'} '
                            'registrada${state.total == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      ElevatedButton.icon(
                        onPressed: () => showFacturaForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Nueva'),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Buscar por número de factura…',
                          hintStyle:
                              TextStyle(color: AppColors.textFaint),
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.textSecondary, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      color: AppColors.textSecondary, size: 18),
                                  onPressed: _limpiarBusqueda,
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface2,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.accent),
                          ),
                        ),
                        onSubmitted: (_) => _buscar(),
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _buscar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text('Buscar'),
                      ),
                    ),
                  ],
                ),
                if (state.search.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _searchController.clear();
                        notifier.limpiarFiltros();
                        setState(() {});
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent),
                      child: Text('Limpiar'),
                    ),
                  ),
                ],
              ],
            ),
          ),
  
          // ── Error ─────────────────────────────────────────────────────────────
          if (state.error != null)
            _ErrorBanner(
              message: state.error!,
              onClose: notifier.clearError,
            ),
  
          // ── Lista ─────────────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : state.facturas.isEmpty
                    ? _EmptyState(tieneFiltos: state.search.isNotEmpty)
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: notifier.load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: state.facturas.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final factura = state.facturas[index];
                            return _FacturaCard(
                              factura: factura,
                              isAdmin: isAdmin,
                              onEdit: () =>
                                  showFacturaForm(context, factura: factura),
                              onDelete: () =>
                                  _confirmarEliminar(context, factura),
                            );
                          },
                        ),
                      ),
          ),
  
          // ── Paginación ────────────────────────────────────────────────────────
          if (!state.isLoading && state.facturas.isNotEmpty)
            _Paginacion(
              page: state.page,
              total: state.total,
              pageSize: state.pageSize,
              hasNext: state.hasNextPage,
              hasPrev: state.hasPreviousPage,
              onNext: notifier.siguientePagina,
              onPrev: notifier.paginaAnterior,
            ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _FacturaCard extends StatelessWidget {
  final Factura factura;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FacturaCard({
    required this.factura,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      color: AppColors.accent, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factura.numeroFactura,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Venta #${factura.idVenta}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${factura.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(color: AppColors.border, height: 1),
            SizedBox(height: 10),
            Row(
              children: [
                _InfoItem(
                    label: 'Subtotal',
                    value: '\$${factura.subtotal.toStringAsFixed(2)}'),
                SizedBox(width: 16),
                _InfoItem(
                    label: 'IVA',
                    value: '\$${factura.iva.toStringAsFixed(2)}'),
                if (factura.fechaEmision != null) ...[
                  SizedBox(width: 16),
                  _InfoItem(
                    label: 'Emisión',
                    value: _formatDate(factura.fechaEmision!),
                  ),
                ],
              ],
            ),
            if (isAdmin) ...[
              SizedBox(height: 10),
              Divider(color: AppColors.border, height: 1),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _AccionBtn(
                    label: 'Editar',
                    icon: Icons.edit_outlined,
                    color: AppColors.accent,
                    onPressed: onEdit,
                  ),
                  if (isAdmin) ...[
                    SizedBox(width: 8),
                    _AccionBtn(
                      label: 'Eliminar',
                      icon: Icons.delete_outline,
                      color: AppColors.error,
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textFaint, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AccionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AccionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.error, size: 16),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool tieneFiltos;
  const _EmptyState({required this.tieneFiltos});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tieneFiltos
                ? Icons.search_off_outlined
                : Icons.receipt_long_outlined,
            color: AppColors.textFaint,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            tieneFiltos
                ? 'Sin resultados con los filtros aplicados'
                : 'No hay facturas registradas',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _Paginacion extends StatelessWidget {
  final int page;
  final int total;
  final int pageSize;
  final bool hasNext;
  final bool hasPrev;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _Paginacion({
    required this.page,
    required this.total,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrev,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final desde = ((page - 1) * pageSize) + 1;
    final hasta = (page * pageSize).clamp(0, total);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$desde–$hasta de $total',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left,
                    color: AppColors.textSecondary),
                onPressed: hasPrev ? onPrev : null,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Pág. $page',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onPressed: hasNext ? onNext : null,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
