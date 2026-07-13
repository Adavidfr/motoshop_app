// lib/presentation/screens/admin/garantias_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/garantia.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garantias_admin_provider.dart';
import '../../widgets/garantia_form.dart';

class GarantiasAdminScreen extends ConsumerStatefulWidget {
  const GarantiasAdminScreen({super.key});

  @override
  ConsumerState<GarantiasAdminScreen> createState() =>
      _GarantiasAdminScreenState();
}

class _GarantiasAdminScreenState
    extends ConsumerState<GarantiasAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(garantiasAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();
    await ref.read(garantiasAdminProvider.notifier).setSearch('');
    if (mounted) setState(() {});
  }

  Future<void> _confirmarEliminar(
      BuildContext context, Garantia garantia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Eliminar garantía',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Eliminar la garantía #${garantia.idGarantia}?',
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
          .read(garantiasAdminProvider.notifier)
          .eliminarGarantia(garantia.idGarantia);
    }
  }

  Future<void> _mostrarCambioEstado(
      BuildContext context, Garantia garantia) async {
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
            Padding(
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
            ...EstadoGarantia.values.map(
              (e) => ListTile(
                leading: Icon(
                  _iconoPorEstado(e.value),
                  color: _colorPorEstado(e.value),
                ),
                title: Text(
                  e.label,
                  style: TextStyle(
                    color: e.value == garantia.estado.value
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: e.value == garantia.estado.value
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: e.value == garantia.estado.value
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
        nuevoEstado != garantia.estado.value &&
        mounted) {
      await ref
          .read(garantiasAdminProvider.notifier)
          .cambiarEstado(garantia.idGarantia, nuevoEstado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(garantiasAdminProvider);
    final notifier = ref.read(garantiasAdminProvider.notifier);
    debugPrint('GarantiasAdminScreen Build: isLoading=${state.isLoading}, error=${state.error}, items=${state.garantias.length}');

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
                            'Garantías',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.total} garantía${state.total == 1 ? '' : 's'} '
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
                        onPressed: () => showGarantiaForm(context),
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
                          hintText: 'Buscar garantía…',
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
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FiltroDropdown(
                        hint: 'Estado',
                        value: state.filtroEstado,
                        items:
                            EstadoGarantia.values.map((e) => e.value).toList(),
                        onChanged: (v) => notifier.setFiltroEstado(v),
                      ),
                    ),
                    if (state.filtroEstado != null ||
                        state.search.isNotEmpty) ...[
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          notifier.limpiarFiltros();
                          setState(() {});
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent),
                        child: Text('Limpiar'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
  
          if (state.error != null)
            _ErrorBanner(
                message: state.error!, onClose: notifier.clearError),
  
          Expanded(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : state.garantias.isEmpty
                    ? _EmptyState(
                        tieneFiltos: state.filtroEstado != null ||
                            state.search.isNotEmpty)
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: notifier.load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: state.garantias.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final garantia = state.garantias[index];
                            return _GarantiaCard(
                              garantia: garantia,
                              isAdmin: isAdmin,
                              onEdit: () => showGarantiaForm(context,
                                  garantia: garantia),
                              onDelete: () =>
                                  _confirmarEliminar(context, garantia),
                              onChangeEstado: () =>
                                  _mostrarCambioEstado(context, garantia),
                            );
                          },
                        ),
                      ),
          ),
  
          if (!state.isLoading && state.garantias.isNotEmpty)
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

class _GarantiaCard extends StatelessWidget {
  final Garantia garantia;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onChangeEstado;

  const _GarantiaCard({
    required this.garantia,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeEstado,
  });

  @override
  Widget build(BuildContext context) {
    final colorEstado = _colorPorEstado(garantia.estado.value);
    final iconoEstado = _iconoPorEstado(garantia.estado.value);

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
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garantía #${garantia.idGarantia}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Venta #${garantia.idVenta} · Moto #${garantia.idMoto}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: colorEstado.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    garantia.estado.label,
                    style: TextStyle(
                      color: colorEstado,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(color: AppColors.border, height: 1),
            SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _InfoItem(
                  label: 'Duración',
                  value: '${garantia.mesesGarantia} mes'
                      '${garantia.mesesGarantia == 1 ? '' : 'es'}',
                ),
                if (garantia.fechaInicio != null)
                  _InfoItem(
                    label: 'Inicio',
                    value: _formatDate(garantia.fechaInicio!),
                  ),
                if (garantia.fechaFin != null)
                  _InfoItem(
                    label: 'Fin',
                    value: _formatDate(garantia.fechaFin!),
                  ),
              ],
            ),
            if (garantia.descripcion != null &&
                garantia.descripcion!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                garantia.descripcion!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isAdmin) ...[
              SizedBox(height: 10),
              Divider(color: AppColors.border, height: 1),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _AccionBtn(
                    label: 'Estado',
                    icon: Icons.swap_horiz_outlined,
                    color: AppColors.info,
                    onPressed: onChangeEstado,
                  ),
                  SizedBox(width: 8),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _colorPorEstado(String estado) {
  switch (estado) {
    case 'Activa':
      return AppColors.success;
    case 'Expirada':
      return AppColors.warning;
    case 'Cancelada':
      return AppColors.error;
    case 'En proceso':
      return AppColors.info;
    default:
      return AppColors.textSecondary;
  }
}

IconData _iconoPorEstado(String estado) {
  switch (estado) {
    case 'Activa':
      return Icons.verified_outlined;
    case 'Expirada':
      return Icons.schedule_outlined;
    case 'Cancelada':
      return Icons.cancel_outlined;
    case 'En proceso':
      return Icons.pending_outlined;
    default:
      return Icons.shield_outlined;
  }
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

// ── Widgets compartidos ───────────────────────────────────────────────────────

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
          SizedBox(width: 8),
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
                : Icons.shield_outlined,
            color: AppColors.textFaint,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            tieneFiltos
                ? 'Sin resultados con los filtros aplicados'
                : 'No hay garantías registradas',
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
