// lib/presentation/screens/admin/notificaciones_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/notificacion.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notificaciones_admin_provider.dart';
import '../../widgets/notificacion_form.dart';

class NotificacionesAdminScreen extends ConsumerStatefulWidget {
  const NotificacionesAdminScreen({super.key});

  @override
  ConsumerState<NotificacionesAdminScreen> createState() =>
      _NotificacionesAdminScreenState();
}

class _NotificacionesAdminScreenState
    extends ConsumerState<NotificacionesAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(notificacionesAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();
    await ref.read(notificacionesAdminProvider.notifier).setSearch('');
    if (mounted) setState(() {});
  }

  Future<void> _confirmarEliminar(
      BuildContext context, Notificacion notif) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Eliminar notificación',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Eliminar la notificación "${notif.titulo}"?',
          style: const TextStyle(color: AppColors.textSecondary),
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
          .read(notificacionesAdminProvider.notifier)
          .eliminarNotificacion(notif.idNotificacion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(notificacionesAdminProvider);
    final notifier = ref.read(notificacionesAdminProvider.notifier);

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
                          'Notificaciones',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} notificación${state.total == 1 ? '' : 'es'} '
                          'registrada${state.total == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => showNotificacionForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar por título o mensaje...',
                        hintStyle:
                            const TextStyle(color: AppColors.textFaint),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textSecondary, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
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
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.accent),
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
                    child: _FiltroLeidoDropdown(
                      value: state.filtroLeido,
                      onChanged: (v) => notifier.setFiltroLeido(v),
                    ),
                  ),
                  if (state.filtroLeido != null ||
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

        // ── Error ─────────────────────────────────────────────────────────────
        if (state.error != null)
          _ErrorBanner(message: state.error!, onClose: notifier.clearError),

        // ── Lista ─────────────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : state.notificaciones.isEmpty
                  ? _EmptyState(
                      tieneFiltos: state.filtroLeido != null ||
                          state.search.isNotEmpty)
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: notifier.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.notificaciones.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = state.notificaciones[index];
                          return _NotificacionCard(
                            notificacion: notif,
                            isAdmin: isAdmin,
                            onEdit: () => showNotificacionForm(context,
                                notificacion: notif),
                            onDelete: () => _confirmarEliminar(context, notif),
                            onToggleLeido: () => notifier.marcarComoLeido(
                                notif.idNotificacion, !notif.leido),
                          );
                        },
                      ),
                    ),
        ),

        // ── Paginación ────────────────────────────────────────────────────────
        if (!state.isLoading && state.notificaciones.isNotEmpty)
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

class _NotificacionCard extends StatelessWidget {
  final Notificacion notificacion;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleLeido;

  const _NotificacionCard({
    required this.notificacion,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleLeido,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notificacion.leido
              ? AppColors.borderLight
              : AppColors.accent.withValues(alpha: 0.3),
          width: notificacion.leido ? 1 : 2,
        ),
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
                  child: Icon(
                    notificacion.leido
                        ? Icons.notifications_none_outlined
                        : Icons.notifications_active_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacion.titulo,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: notificacion.leido
                              ? FontWeight.w500
                              : FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Usuario #${notificacion.idUsuario}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleLeido,
                  icon: Icon(
                    notificacion.leido
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    color: notificacion.leido
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  tooltip: notificacion.leido
                      ? 'Marcar como no leído'
                      : 'Marcar como leído',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Text(
              notificacion.mensaje,
              style: TextStyle(
                color: notificacion.leido
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            if (notificacion.fechaCreacion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Enviada: ${_formatDate(notificacion.fechaCreacion!)}',
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                ),
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$d/$m/${date.year} a las $hh:$mm';
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

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

class _FiltroLeidoDropdown extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _FiltroLeidoDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<bool>(
      isExpanded: true,
      value: value,
      hint: const Text('Estado lectura',
          style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
      dropdownColor: AppColors.surface2,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      items: const [
        DropdownMenuItem<bool>(
          value: true,
          child: Text('Leídos'),
        ),
        DropdownMenuItem<bool>(
          value: false,
          child: Text('No leídos'),
        ),
      ],
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
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          IconButton(
            icon:
                const Icon(Icons.close, color: AppColors.error, size: 16),
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
                : Icons.notifications_off_outlined,
            color: AppColors.textFaint,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            tieneFiltos
                ? 'Sin resultados con los filtros aplicados'
                : 'No hay notificaciones registradas',
            style: const TextStyle(
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
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
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
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
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
