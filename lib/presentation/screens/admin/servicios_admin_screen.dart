import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/servicio.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/servicios_admin_provider.dart';
import '../../widgets/servicio_form.dart';

class ServiciosAdminScreen extends ConsumerStatefulWidget {
  const ServiciosAdminScreen({
    super.key,
  });

  @override
  ConsumerState<ServiciosAdminScreen> createState() {
    return _ServiciosAdminScreenState();
  }
}

class _ServiciosAdminScreenState
    extends ConsumerState<ServiciosAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(serviciosAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();

    await ref
        .read(serviciosAdminProvider.notifier)
        .setSearch('');

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(serviciosAdminProvider);
    final notifier = ref.read(
      serviciosAdminProvider.notifier,
    );

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            12,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Servicios',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} servicio${state.total == 1 ? '' : 's'} '
                          'registrado${state.total == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showServicioForm(
                        context,
                        ref,
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                    ),
                    label: const Text('Nuevo'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction:
                          TextInputAction.search,
                      onSubmitted: (_) => _buscar(),
                      decoration: InputDecoration(
                        hintText:
                            'Buscar por nombre o descripción...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color:
                              AppColors.textSecondary,
                        ),
                        suffixIcon:
                            _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed:
                                        _limpiarBusqueda,
                                    icon: const Icon(
                                      Icons.close,
                                    ),
                                  ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton.filled(
                    onPressed:
                        state.isLoading ? null : _buscar,
                    icon: const Icon(
                      Icons.search,
                    ),
                    tooltip: 'Buscar',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _EstadoFilter(
                      selected: state.filtroEstado,
                      onChanged: state.isLoading
                          ? null
                          : notifier.setFiltroEstado,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _OrderingMenu(
                          selected: state.ordering,
                          enabled: !state.isLoading,
                          onChanged: notifier.setOrdering,
                        ),
                      ),

                      if (state.search.isNotEmpty ||
                          state.filtroEstado != null ||
                          state.ordering != 'nombre') ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  _searchController.clear();

                                  await notifier.limpiarFiltros();

                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                          icon: const Icon(
                            Icons.filter_alt_off_outlined,
                          ),
                          tooltip: 'Limpiar filtros',
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: Builder(
            builder: (_) {
              if (state.isLoading &&
                  state.servicios.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                );
              }

              if (state.error != null &&
                  state.servicios.isEmpty) {
                return _ErrorView(
                  message: state.error!,
                  onRetry: notifier.load,
                );
              }

              if (state.servicios.isEmpty) {
                return _EmptyView(
                  hasFilters:
                      state.search.isNotEmpty ||
                          state.filtroEstado != null,
                );
              }

              return RefreshIndicator(
                onRefresh: notifier.load,
                color: AppColors.accent,
                child: ListView.separated(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      state.servicios.length + 1,
                  separatorBuilder: (_, index) {
                    if (index ==
                        state.servicios.length - 1) {
                      return const SizedBox(height: 16);
                    }

                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (_, index) {
                    if (index ==
                        state.servicios.length) {
                      return _PaginationControls(
                        page: state.page,
                        pageSize: state.pageSize,
                        total: state.total,
                        hasPrevious:
                            state.hasPreviousPage,
                        hasNext: state.hasNextPage,
                        isLoading: state.isLoading,
                        onPrevious:
                            notifier.paginaAnterior,
                        onNext:
                            notifier.siguientePagina,
                        onPageSizeChanged:
                            notifier.setPageSize,
                      );
                    }

                    final servicio =
                        state.servicios[index];

                    return _ServicioCard(
                      servicio: servicio,
                      canDelete: isAdmin,
                      onToggle: () {
                        notifier.toggleEstado(
                          servicio.id,
                          !servicio.estado,
                        );
                      },
                      onEdit: () {
                        showServicioForm(
                          context,
                          ref,
                          initial: servicio,
                        );
                      },
                      onDelete: () {
                        _confirmDelete(
                          context,
                          servicio,
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    Servicio servicio,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '¿Eliminar servicio?',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            '"${servicio.nombre}" se eliminará permanentemente.\n\n'
            'Si está asociado a mantenimientos, el servidor podría impedir '
            'su eliminación. En ese caso puedes desactivarlo.',
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await ref
                    .read(
                      serviciosAdminProvider.notifier,
                    )
                    .eliminarServicio(servicio.id);

                if (!mounted) {
                  return;
                }

                final error = ref
                    .read(serviciosAdminProvider)
                    .error;

                if (error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor:
                          AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EstadoFilter extends StatelessWidget {
  final bool? selected;
  final ValueChanged<bool?>? onChanged;

  const _EstadoFilter({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool?>(
      segments: const [
        ButtonSegment<bool?>(
          value: null,
          label: Text(
            'Todos',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.list_alt_outlined,
            size: 18,
          ),
        ),
        ButtonSegment<bool?>(
          value: true,
          label: Text(
            'Activos',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.check_circle_outline,
            size: 18,
          ),
        ),
        ButtonSegment<bool?>(
          value: false,
          label: Text(
            'Inactivos',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.block_outlined,
            size: 18,
          ),
        ),
      ],
      selected: <bool?>{selected},
      onSelectionChanged: onChanged == null
          ? null
          : (values) {
              onChanged!(values.first);
            },
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(
          const Size(0, 46),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: 8,
          ),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return AppColors.accent.withValues(
                alpha: 0.15,
              );
            }

            return AppColors.surface2;
          },
        ),
        foregroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return AppColors.accent;
            }

            return AppColors.textSecondary;
          },
        ),
        side: WidgetStateProperty.all(
          const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _OrderingMenu extends StatelessWidget {
  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _OrderingMenu({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: enabled,
      initialValue: selected,
      tooltip: 'Ordenar',
      color: AppColors.surface2,
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'nombre',
          child: Text('Nombre A-Z'),
        ),
        PopupMenuItem(
          value: '-nombre',
          child: Text('Nombre Z-A'),
        ),
        PopupMenuItem(
          value: 'precio_base',
          child: Text('Menor precio'),
        ),
        PopupMenuItem(
          value: '-precio_base',
          child: Text('Mayor precio'),
        ),
        PopupMenuItem(
          value: 'tiempo_estimado_minutos',
          child: Text('Menor duración'),
        ),
        PopupMenuItem(
          value: '-tiempo_estimado_minutos',
          child: Text('Mayor duración'),
        ),
        PopupMenuItem(
          value: '-fecha_creacion',
          child: Text('Más recientes'),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.sort,
              size: 18,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              'Ordenar',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicioCard extends StatelessWidget {
  final Servicio servicio;
  final bool canDelete;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServicioCard({
    required this.servicio,
    required this.canDelete,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: servicio.estado ? 1 : 0.58,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Switch(
              value: servicio.estado,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppColors.accent,
              trackColor:
                  WidgetStateProperty.resolveWith(
                (states) {
                  if (states.contains(
                    WidgetState.selected,
                  )) {
                    return AppColors.accent
                        .withValues(alpha: 0.4);
                  }

                  return AppColors.border;
                },
              ),
            ),

            const SizedBox(width: 4),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          servicio.nombre,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _EstadoBadge(
                        activo: servicio.estado,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  _InfoRow(
                    icon: Icons.attach_money,
                    text:
                        '\$ ${servicio.precioBase.toStringAsFixed(2)}',
                    highlight: true,
                  ),

                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    text:
                        '${servicio.tiempoEstimadoMinutos} minutos',
                  ),

                  if (_tieneTexto(
                    servicio.descripcion,
                  ))
                    _InfoRow(
                      icon:
                          Icons.description_outlined,
                      text: servicio.descripcion!,
                      maxLines: 3,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            Column(
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                  ),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  tooltip: 'Editar',
                ),
                if (canDelete)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                    ),
                    color: AppColors.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    tooltip: 'Eliminar',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _tieneTexto(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? AppColors.accent
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: highlight
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final bool activo;

  const _EstadoBadge({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo
        ? AppColors.success
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int page;
  final int pageSize;
  final int total;
  final bool hasPrevious;
  final bool hasNext;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onPageSizeChanged;

  const _PaginationControls({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasPrevious,
    required this.hasNext,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages =
        total == 0 ? 1 : (total / pageSize).ceil();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Página $page de $totalPages',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isLoading || !hasPrevious
                          ? null
                          : onPrevious,
                  icon: const Icon(
                    Icons.chevron_left,
                  ),
                  label: const Text('Anterior'),
                ),
              ),

              const SizedBox(width: 10),

              DropdownButton<int>(
                value: pageSize,
                dropdownColor: AppColors.surface2,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                ),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: 10,
                    child: Text('10'),
                  ),
                  DropdownMenuItem(
                    value: 20,
                    child: Text('20'),
                  ),
                  DropdownMenuItem(
                    value: 50,
                    child: Text('50'),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          onPageSizeChanged(value);
                        }
                      },
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading || !hasNext
                          ? null
                          : onNext,
                  icon: const Icon(
                    Icons.chevron_right,
                  ),
                  label: const Text('Siguiente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasFilters;

  const _EmptyView({
    required this.hasFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.build_circle_outlined,
            color: AppColors.textFaint,
            size: 55,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'No se encontraron servicios'
                : 'No existen servicios registrados',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFilters
                ? 'Prueba con otros términos o filtros.'
                : 'Registra el primer servicio para comenzar.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}