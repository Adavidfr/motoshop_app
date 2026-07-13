// lib/presentation/screens/admin/historial_estado_venta_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/historial_estado_venta.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/historial_estado_venta_provider.dart';
import '../../widgets/historial_form.dart';

class HistorialEstadoVentaAdminScreen extends ConsumerStatefulWidget {
  const HistorialEstadoVentaAdminScreen({super.key});

  @override
  ConsumerState<HistorialEstadoVentaAdminScreen> createState() =>
      _HistorialEstadoVentaAdminScreenState();
}

class _HistorialEstadoVentaAdminScreenState
    extends ConsumerState<HistorialEstadoVentaAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(historialEstadoVentaProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();
    await ref.read(historialEstadoVentaProvider.notifier).setSearch('');
    if (mounted) setState(() {});
  }

  Future<void> _confirmarEliminar(
      BuildContext context, HistorialEstadoVenta h) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Eliminar historial',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Eliminar el registro de historial (ID: ${h.idHistorial})?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref
          .read(historialEstadoVentaProvider.notifier)
          .eliminarHistorial(h.idHistorial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(historialEstadoVentaProvider);
    final notifier = ref.read(historialEstadoVentaProvider.notifier);

    return Column(
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
                        const Text(
                          'Historial de Ventas',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} registro${state.total == 1 ? '' : 's'}',
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
                      onPressed: () => showHistorialForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(Icons.add, size: 18),
                      label: const Text('Registrar'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar por ID de venta...',
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
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _buscar(),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      child: const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              if (state.search.isNotEmpty) ...[
                const SizedBox(height: 8),
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
                    child: const Text('Limpiar'),
                  ),
                ),
              ],
            ],
          ),
        ),

        if (state.error != null)
          _ErrorBanner(
            message: state.error!,
            onClose: notifier.clearError,
          ),

        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : state.historial.isEmpty
                  ? _EmptyState(tieneFiltos: state.search.isNotEmpty)
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: notifier.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.historial.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final h = state.historial[index];
                          return _HistorialCard(
                            historial: h,
                            isAdmin: isAdmin,
                            onDelete: () => _confirmarEliminar(context, h),
                          );
                        },
                      ),
                    ),
        ),

        if (!state.isLoading && state.historial.isNotEmpty)
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
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _HistorialCard extends StatelessWidget {
  final HistorialEstadoVenta historial;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _HistorialCard({
    required this.historial,
    required this.isAdmin,
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
                  child: Icon(Icons.history_outlined,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venta #${historial.idVenta}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (historial.fechaCambio != null)
                        Text(
                          _formatDate(historial.fechaCambio!),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isAdmin)
                  _AccionBtn(
                    label: 'Eliminar',
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Estado Anterior',
                    value: historial.estadoAnterior ?? 'N/A',
                  ),
                ),
                Icon(Icons.arrow_forward_outlined,
                    color: AppColors.textFaint, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoItem(
                    label: 'Estado Nuevo',
                    value: historial.estadoNuevo,
                    colorValue: AppColors.accent,
                  ),
                ),
              ],
            ),
            if (historial.observacion != null &&
                historial.observacion!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Observación',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                historial.observacion!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
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
  final Color? colorValue;
  const _InfoItem(
      {required this.label, required this.value, this.colorValue});

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
                color: colorValue ?? AppColors.textPrimary,
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
          const SizedBox(width: 8),
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
                : Icons.history_outlined,
            color: AppColors.textFaint,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            tieneFiltos
                ? 'Sin resultados con los filtros aplicados'
                : 'No hay historial registrado',
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
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$d/$m/${date.year} $hh:$mm';
}
