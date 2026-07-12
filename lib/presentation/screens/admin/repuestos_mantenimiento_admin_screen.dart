import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/repuesto_mantenimiento.dart';
import '../../../theme/app_colors.dart';
import '../../providers/repuestos_mantenimiento_admin_provider.dart';
import '../../widgets/repuesto_mantenimiento_form.dart';

class RepuestosMantenimientoAdminScreen
    extends ConsumerStatefulWidget {
  const RepuestosMantenimientoAdminScreen({
    super.key,
  });

  @override
  ConsumerState<RepuestosMantenimientoAdminScreen>
      createState() {
    return _RepuestosMantenimientoAdminScreenState();
  }
}

class _RepuestosMantenimientoAdminScreenState
    extends ConsumerState<
        RepuestosMantenimientoAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(
          repuestosMantenimientoAdminProvider.notifier,
        )
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();

    await ref
        .read(
          repuestosMantenimientoAdminProvider.notifier,
        )
        .setSearch('');

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      repuestosMantenimientoAdminProvider,
    );

    final notifier = ref.read(
      repuestosMantenimientoAdminProvider.notifier,
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
                          'Repuestos de mantenimiento',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} registro'
                          '${state.total == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: state.isLoadingCatalogos
                        ? null
                        : () {
                            showRepuestoMantenimientoForm(
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
                            'Buscar por nombre de repuesto...',
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

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _OrderingMenu(
                      selected: state.ordering,
                      enabled: !state.isLoading,
                      onChanged:
                          notifier.setOrdering,
                    ),
                  ),
                  if (state.search.isNotEmpty ||
                      state.ordering !=
                          'id_repuesto_mantenimiento') ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              _searchController.clear();

                              await notifier.setSearch('');
                              await notifier.setOrdering(
                                'id_repuesto_mantenimiento',
                              );

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
        ),

        Expanded(
          child: Builder(
            builder: (_) {
              if (state.isLoading &&
                  state.registros.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                );
              }

              if (state.error != null &&
                  state.registros.isEmpty) {
                return _ErrorView(
                  message: state.error!,
                  onRetry: notifier.load,
                );
              }

              if (state.registros.isEmpty) {
                return _EmptyView(
                  hasFilters:
                      state.search.isNotEmpty,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await notifier.load();
                  await notifier.cargarCatalogos();
                },
                color: AppColors.accent,
                child: ListView.separated(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      state.registros.length + 1,
                  separatorBuilder: (_, index) {
                    if (index ==
                        state.registros.length - 1) {
                      return const SizedBox(height: 16);
                    }

                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (_, index) {
                    if (index ==
                        state.registros.length) {
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

                    final registro =
                        state.registros[index];

                    final mantenimiento =
                        state.mantenimientoPorId(
                      registro.mantenimientoId,
                    );

                    final repuesto =
                        state.repuestoPorId(
                      registro.repuestoId,
                    );

                    return _RepuestoMantenimientoCard(
                      registro: registro,
                      mantenimientoNombre:
                          mantenimiento == null
                              ? 'Mantenimiento #${registro.mantenimientoId}'
                              : 'Mantenimiento #${mantenimiento.idMantenimiento}',
                      repuestoNombre:
                          repuesto == null
                              ? 'Repuesto #${registro.repuestoId}'
                              : '${repuesto.nombre} (${repuesto.sku})',
                      onEdit: () {
                        showRepuestoMantenimientoForm(
                          context,
                          ref,
                          initial: registro,
                        );
                      },
                      onDelete: () {
                        _confirmDelete(
                          context,
                          registro,
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
    RepuestoMantenimiento registro,
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
            '¿Eliminar registro?',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'El repuesto asociado al mantenimiento '
            '#${registro.mantenimientoId} se eliminará permanentemente.',
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
                      repuestosMantenimientoAdminProvider
                          .notifier,
                    )
                    .eliminar(
                      registro
                          .idRepuestoMantenimiento,
                    );

                if (!mounted) {
                  return;
                }

                final error = ref
                    .read(
                      repuestosMantenimientoAdminProvider,
                    )
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
      tooltip: 'Ordenar registros',
      color: AppColors.surface2,
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'id_repuesto_mantenimiento',
          child: Text('Más antiguos'),
        ),
        PopupMenuItem(
          value: '-id_repuesto_mantenimiento',
          child: Text('Más recientes'),
        ),
        PopupMenuItem(
          value: '-cantidad',
          child: Text('Mayor cantidad'),
        ),
        PopupMenuItem(
          value: 'cantidad',
          child: Text('Menor cantidad'),
        ),
        PopupMenuItem(
          value: '-precio_unitario',
          child: Text('Mayor precio'),
        ),
        PopupMenuItem(
          value: 'precio_unitario',
          child: Text('Menor precio'),
        ),
        PopupMenuItem(
          value: '-subtotal',
          child: Text('Mayor subtotal'),
        ),
        PopupMenuItem(
          value: 'subtotal',
          child: Text('Menor subtotal'),
        ),
      ],
      child: Container(
        height: 42,
        width: double.infinity,
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
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sort,
              size: 18,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              'Ordenar registros',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepuestoMantenimientoCard
    extends StatelessWidget {
  final RepuestoMantenimiento registro;
  final String mantenimientoNombre;
  final String repuestoNombre;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RepuestoMantenimientoCard({
    required this.registro,
    required this.mantenimientoNombre,
    required this.repuestoNombre,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registro #${registro.idRepuestoMantenimiento}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                ),
                color: AppColors.textSecondary,
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                ),
                color: AppColors.error,
                tooltip: 'Eliminar',
              ),
            ],
          ),

          const SizedBox(height: 8),

          _InfoRow(
            label: 'Mantenimiento',
            value: mantenimientoNombre,
          ),

          _InfoRow(
            label: 'Repuesto',
            value: repuestoNombre,
          ),

          _InfoRow(
            label: 'Cantidad',
            value: registro.cantidad.toString(),
          ),

          _InfoRow(
            label: 'Precio unitario',
            value:
                '\$ ${registro.precioUnitario.toStringAsFixed(2)}',
          ),

          const Divider(
            height: 22,
            color: AppColors.border,
          ),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subtotal',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$ ${registro.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textFaint,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
                child: OutlinedButton(
                  onPressed:
                      isLoading || !hasPrevious
                          ? null
                          : onPrevious,
                  child: const Text('Anterior'),
                ),
              ),

              const SizedBox(width: 10),

              DropdownButton<int>(
                value: pageSize,
                dropdownColor: AppColors.surface2,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                ),
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
                child: ElevatedButton(
                  onPressed:
                      isLoading || !hasNext
                          ? null
                          : onNext,
                  child: const Text('Siguiente'),
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
            Icons.settings_suggest_outlined,
            color: AppColors.textFaint,
            size: 55,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'No se encontraron registros'
                : 'No existen repuestos asociados',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFilters
                ? 'Prueba con otro término de búsqueda.'
                : 'Agrega un repuesto a un mantenimiento.',
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