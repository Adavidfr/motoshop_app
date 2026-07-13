// lib/presentation/screens/admin/pagos_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/pago.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pagos_admin_provider.dart';
import '../../widgets/pago_form.dart';

class PagosAdminScreen extends ConsumerStatefulWidget {
  const PagosAdminScreen({super.key});

  @override
  ConsumerState<PagosAdminScreen> createState() => _PagosAdminScreenState();
}

class _PagosAdminScreenState extends ConsumerState<PagosAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(pagosAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();
    await ref.read(pagosAdminProvider.notifier).setSearch('');
    if (mounted) setState(() {});
  }

  // ── Confirmación de eliminación ───────────────────────────────────────────

  Future<void> _confirmarEliminar(
    BuildContext context,
    Pago pago,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text(
          'Eliminar pago',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Eliminar el pago #${pago.idPago} de \$${pago.monto.toStringAsFixed(2)}?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
          .read(pagosAdminProvider.notifier)
          .eliminarPago(pago.idPago);
    }
  }

  // ── Cambio de estado rápido ───────────────────────────────────────────────

  Future<void> _mostrarCambioEstado(
    BuildContext context,
    Pago pago,
  ) async {
    final nuevoEstado = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Cambiar estado',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(color: AppColors.border),
            ...EstadoPago.values.map(
              (e) => ListTile(
                leading: Icon(
                  _iconoPorEstado(e.value),
                  color: _colorPorEstado(e.value),
                ),
                title: Text(
                  e.label,
                  style: TextStyle(
                    color: e.value == pago.estado.value
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: e.value == pago.estado.value
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: e.value == pago.estado.value
                    ? Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () => Navigator.pop(context, e.value),
              ),
            ),
          ],
        ),
      ),
    );

    if (nuevoEstado != null &&
        nuevoEstado != pago.estado.value &&
        mounted) {
      await ref
          .read(pagosAdminProvider.notifier)
          .cambiarEstado(pago.idPago, nuevoEstado);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(pagosAdminProvider);
    final notifier = ref.read(pagosAdminProvider.notifier);

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
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
                          'Pagos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} pago${state.total == 1 ? '' : 's'} '
                          'registrado${state.total == 1 ? '' : 's'}',
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
                      onPressed: () => showPagoForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Barra de búsqueda ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar por referencia…',
                        hintStyle:
                            TextStyle(color: AppColors.textFaint),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
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
                  const SizedBox(width: 8),
                  _BotonBuscar(onPressed: _buscar),
                ],
              ),
              const SizedBox(height: 10),

              // ── Filtros ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _FiltroDropdown(
                      hint: 'Estado',
                      value: state.filtroEstado,
                      items: EstadoPago.values
                          .map((e) => e.value)
                          .toList(),
                      onChanged: (v) => notifier.setFiltroEstado(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FiltroDropdown(
                      hint: 'Método',
                      value: state.filtroMetodo,
                      items: MetodoPago.values
                          .map((m) => m.value)
                          .toList(),
                      onChanged: (v) => notifier.setFiltroMetodo(v),
                    ),
                  ),
                  if (state.filtroEstado != null ||
                      state.filtroMetodo != null ||
                      state.search.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        notifier.limpiarFiltros();
                        setState(() {});
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ── Error global ────────────────────────────────────────────────────
        if (state.error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: AppColors.error, size: 16),
                  onPressed: notifier.clearError,
                ),
              ],
            ),
          ),

        // ── Lista ───────────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                )
              : state.pagos.isEmpty
                  ? _EmptyState(
                      tieneFiltos: state.filtroEstado != null ||
                          state.filtroMetodo != null ||
                          state.search.isNotEmpty,
                    )
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: notifier.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.pagos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final pago = state.pagos[index];
                          return _PagoCard(
                            pago: pago,
                            isAdmin: isAdmin,
                            onEdit: () => showPagoForm(
                              context,
                              pago: pago,
                            ),
                            onDelete: () =>
                                _confirmarEliminar(context, pago),
                            onChangeEstado: () =>
                                _mostrarCambioEstado(context, pago),
                          );
                        },
                      ),
                    ),
        ),

        // ── Paginación ──────────────────────────────────────────────────────
        if (!state.isLoading && state.pagos.isNotEmpty)
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

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _BotonBuscar extends StatelessWidget {
  final VoidCallback onPressed;
  const _BotonBuscar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
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
    );
  }
}

class _FiltroDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FiltroDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
          dropdownColor: AppColors.surface2,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Todos',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Card de pago ──────────────────────────────────────────────────────────────

class _PagoCard extends StatelessWidget {
  final Pago pago;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onChangeEstado;

  const _PagoCard({
    required this.pago,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeEstado,
  });

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorPorEstado(pago.estado.value);
    final iconoEstado = _iconoPorEstado(pago.estado.value);
    final colorMetodo = _colorPorMetodo(pago.metodoPago.value);

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
            // ── Fila superior ──────────────────────────────────────────────
            Row(
              children: [
                // Ícono del estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconoEstado, color: colorEstado, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pago #${pago.idPago}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Venta #${pago.idVenta}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Monto destacado
                Text(
                  '\$${pago.monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),

            // ── Chips de info ──────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  label: pago.estado.label,
                  color: colorEstado,
                  icon: iconoEstado,
                ),
                _Chip(
                  label: pago.metodoPago.label,
                  color: colorMetodo,
                  icon: _iconoPorMetodo(pago.metodoPago.value),
                ),
                if (pago.fechaPago != null)
                  _Chip(
                    label: _formatDate(pago.fechaPago!),
                    color: AppColors.textSecondary,
                    icon: Icons.calendar_today_outlined,
                  ),
              ],
            ),

            // ── Referencia ─────────────────────────────────────────────────
            if (pago.referencia != null && pago.referencia!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.tag_outlined,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pago.referencia!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],

            // ── Acciones (solo admin) ──────────────────────────────────────
            if (isAdmin) ...[
              const SizedBox(height: 10),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cambiar estado
                  _AccionBoton(
                    label: 'Estado',
                    icon: Icons.swap_horiz_outlined,
                    color: AppColors.info,
                    onPressed: onChangeEstado,
                  ),
                  const SizedBox(width: 8),
                  // Editar
                  _AccionBoton(
                    label: 'Editar',
                    icon: Icons.edit_outlined,
                    color: AppColors.accent,
                    onPressed: onEdit,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 8),
                    _AccionBoton(
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Chip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionBoton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AccionBoton({
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

// ── Paginación ────────────────────────────────────────────────────────────────

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
          Text(
            '$desde–$hasta de $total',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: AppColors.textSecondary,
                ),
                onPressed: hasPrev ? onPrev : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pág. $page',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
                onPressed: hasNext ? onNext : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

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
                : Icons.payment_outlined,
            color: AppColors.textFaint,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            tieneFiltos
                ? 'Sin resultados con los filtros aplicados'
                : 'No hay pagos registrados',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          if (tieneFiltos) ...[
            const SizedBox(height: 8),
            const Text(
              'Prueba con otros filtros o limpia la búsqueda',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers de color e ícono ──────────────────────────────────────────────────

Color _colorPorEstado(String estado) {
  switch (estado) {
    case 'Completado':
      return AppColors.success;
    case 'Pendiente':
      return AppColors.warning;
    case 'Fallido':
      return AppColors.error;
    case 'Reembolsado':
      return AppColors.info;
    default:
      return AppColors.textSecondary;
  }
}

IconData _iconoPorEstado(String estado) {
  switch (estado) {
    case 'Completado':
      return Icons.check_circle_outline;
    case 'Pendiente':
      return Icons.schedule_outlined;
    case 'Fallido':
      return Icons.cancel_outlined;
    case 'Reembolsado':
      return Icons.replay_outlined;
    default:
      return Icons.payment_outlined;
  }
}

Color _colorPorMetodo(String metodo) {
  switch (metodo) {
    case 'Efectivo':
      return AppColors.success;
    case 'Tarjeta':
      return AppColors.info;
    case 'Transferencia':
      return AppColors.accent;
    case 'Cheque':
      return AppColors.warning;
    default:
      return AppColors.textSecondary;
  }
}

IconData _iconoPorMetodo(String metodo) {
  switch (metodo) {
    case 'Efectivo':
      return Icons.attach_money;
    case 'Tarjeta':
      return Icons.credit_card_outlined;
    case 'Transferencia':
      return Icons.swap_horiz;
    case 'Cheque':
      return Icons.receipt_long_outlined;
    default:
      return Icons.payment_outlined;
  }
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}
