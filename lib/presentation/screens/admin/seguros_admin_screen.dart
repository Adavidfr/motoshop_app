// lib/presentation/screens/admin/seguros_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/seguro.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seguros_admin_provider.dart';
import '../../widgets/seguro_form.dart';

class SegurosAdminScreen extends ConsumerStatefulWidget {
  const SegurosAdminScreen({super.key});

  @override
  ConsumerState<SegurosAdminScreen> createState() =>
      _SegurosAdminScreenState();
}

class _SegurosAdminScreenState extends ConsumerState<SegurosAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(segurosAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();
    await ref.read(segurosAdminProvider.notifier).setSearch('');
    if (mounted) setState(() {});
  }

  Future<void> _confirmarEliminar(
      BuildContext context, Seguro seguro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Eliminar seguro',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Eliminar el seguro ${seguro.numeroPoliza}?',
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
          .read(segurosAdminProvider.notifier)
          .eliminarSeguro(seguro.idSeguro);
    }
  }

  Future<void> _mostrarCambioEstado(
      BuildContext context, Seguro seguro) async {
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
            ...EstadoSeguro.values.map(
              (e) => ListTile(
                leading: Icon(
                  _iconoPorEstado(e.value),
                  color: _colorPorEstado(e.value),
                ),
                title: Text(
                  e.label,
                  style: TextStyle(
                    color: e.value == seguro.estado.value
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: e.value == seguro.estado.value
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: e.value == seguro.estado.value
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
        nuevoEstado != seguro.estado.value &&
        mounted) {
      await ref
          .read(segurosAdminProvider.notifier)
          .cambiarEstado(seguro.idSeguro, nuevoEstado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(segurosAdminProvider);
    final notifier = ref.read(segurosAdminProvider.notifier);

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
                          'Seguros',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} seguro${state.total == 1 ? '' : 's'} '
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
                      onPressed: () => showSeguroForm(context),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar por aseguradora o póliza…',
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FiltroDropdown(
                      hint: 'Estado',
                      value: state.filtroEstado,
                      items: EstadoSeguro.values.map((e) => e.value).toList(),
                      onChanged: (v) => notifier.setFiltroEstado(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FiltroDropdown(
                      hint: 'Cobertura',
                      value: state.filtroCobertura,
                      items:
                          TipoCobertura.values.map((t) => t.value).toList(),
                      onChanged: (v) => notifier.setFiltroCobertura(v),
                    ),
                  ),
                  if (state.filtroEstado != null ||
                      state.filtroCobertura != null ||
                      state.search.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        notifier.limpiarFiltros();
                        setState(() {});
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent),
                      child: const Text('Limpiar'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (state.error != null)
          _ErrorBanner(message: state.error!, onClose: notifier.clearError),

        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : state.seguros.isEmpty
                  ? _EmptyState(
                      tieneFiltos: state.filtroEstado != null ||
                          state.filtroCobertura != null ||
                          state.search.isNotEmpty)
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: notifier.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.seguros.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final seguro = state.seguros[index];
                          return _SeguroCard(
                            seguro: seguro,
                            isAdmin: isAdmin,
                            onEdit: () =>
                                showSeguroForm(context, seguro: seguro),
                            onDelete: () =>
                                _confirmarEliminar(context, seguro),
                            onChangeEstado: () =>
                                _mostrarCambioEstado(context, seguro),
                          );
                        },
                      ),
                    ),
        ),

        if (!state.isLoading && state.seguros.isNotEmpty)
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

class _SeguroCard extends StatelessWidget {
  final Seguro seguro;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onChangeEstado;

  const _SeguroCard({
    required this.seguro,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeEstado,
  });

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorPorEstado(seguro.estado.value);
    final iconoEstado = _iconoPorEstado(seguro.estado.value);
    final colorCobertura = _colorPorCobertura(seguro.tipoCobertura.value);

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
                        seguro.aseguradora,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        seguro.numeroPoliza,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${seguro.costoAnual.toStringAsFixed(2)}/año',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  label: seguro.estado.label,
                  color: colorEstado,
                  icon: iconoEstado,
                ),
                _Chip(
                  label: seguro.tipoCobertura.label,
                  color: colorCobertura,
                  icon: Icons.policy_outlined,
                ),
                if (seguro.fechaInicio != null)
                  _Chip(
                    label: _formatDate(seguro.fechaInicio!),
                    color: AppColors.textSecondary,
                    icon: Icons.calendar_today_outlined,
                  ),
                if (seguro.fechaFin != null)
                  _Chip(
                    label: 'Vence: ${_formatDate(seguro.fechaFin!)}',
                    color: AppColors.warning,
                    icon: Icons.event_available_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Venta #${seguro.idVenta}',
              style: TextStyle(
                  color: AppColors.textFaint, fontSize: 11),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 10),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _AccionBtn(
                    label: 'Estado',
                    icon: Icons.swap_horiz_outlined,
                    color: AppColors.info,
                    onPressed: onChangeEstado,
                  ),
                  const SizedBox(width: 8),
                  _AccionBtn(
                    label: 'Editar',
                    icon: Icons.edit_outlined,
                    color: AppColors.accent,
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _AccionBtn(
                    label: 'Eliminar',
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _colorPorEstado(String estado) {
  switch (estado) {
    case 'Activo':
      return AppColors.success;
    case 'Pendiente':
      return AppColors.warning;
    case 'Vencido':
      return AppColors.error;
    case 'Cancelado':
      return AppColors.textSecondary;
    default:
      return AppColors.textSecondary;
  }
}

IconData _iconoPorEstado(String estado) {
  switch (estado) {
    case 'Activo':
      return Icons.verified_outlined;
    case 'Pendiente':
      return Icons.pending_outlined;
    case 'Vencido':
      return Icons.error_outline;
    case 'Cancelado':
      return Icons.cancel_outlined;
    default:
      return Icons.policy_outlined;
  }
}

Color _colorPorCobertura(String tipo) {
  switch (tipo) {
    case 'Básica':
      return AppColors.info;
    case 'Completa':
      return AppColors.success;
    case 'Terceros':
      return AppColors.warning;
    case 'Todos los riesgos':
      return AppColors.accent;
    default:
      return AppColors.textSecondary;
  }
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

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
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
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
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      hint: Text(hint, style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
      dropdownColor: AppColors.surface2,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: (v) => onChanged(v),
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
                style:
                    TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          IconButton(
            icon:
                Icon(Icons.close, color: AppColors.error, size: 16),
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
                : Icons.policy_outlined,
            color: AppColors.textFaint,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            tieneFiltos
                ? 'Sin resultados con los filtros aplicados'
                : 'No hay seguros registrados',
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
