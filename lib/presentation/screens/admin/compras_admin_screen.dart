import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/model/compra.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/compras_admin_provider.dart';
import '../../widgets/compra_form.dart';

class ComprasAdminScreen extends ConsumerStatefulWidget {
  const ComprasAdminScreen({
    super.key,
  });

  @override
  ConsumerState<ComprasAdminScreen> createState() {
    return _ComprasAdminScreenState();
  }
}

class _ComprasAdminScreenState
    extends ConsumerState<ComprasAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(comprasAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();

    await ref
        .read(comprasAdminProvider.notifier)
        .setSearch('');

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(comprasAdminProvider);
    final notifier = ref.read(
      comprasAdminProvider.notifier,
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
                          'Compras',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} compra${state.total == 1 ? '' : 's'} '
                          'registrada${state.total == 1 ? '' : 's'}',
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
                            showCompraForm(
                              context,
                              ref,
                            );
                          },
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                    ),
                    label: const Text('Nueva'),
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
                            'Buscar por proveedor, moto, repuesto o estado...',
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

              SizedBox(
                width: double.infinity,
                child: _EstadoCompraFilter(
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
                      onChanged:
                          notifier.setOrdering,
                    ),
                  ),

                  if (state.search.isNotEmpty ||
                      state.filtroEstado != null ||
                      state.ordering !=
                          '-fecha_compra') ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              _searchController.clear();

                              await notifier
                                  .limpiarFiltros();

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
                  state.compras.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                );
              }

              if (state.error != null &&
                  state.compras.isEmpty) {
                return _ErrorView(
                  message: state.error!,
                  onRetry: notifier.load,
                );
              }

              if (state.compras.isEmpty) {
                return _EmptyView(
                  hasFilters:
                      state.search.isNotEmpty ||
                          state.filtroEstado != null,
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
                      state.compras.length + 1,
                  separatorBuilder: (_, index) {
                    if (index ==
                        state.compras.length - 1) {
                      return const SizedBox(height: 16);
                    }

                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (_, index) {
                    if (index ==
                        state.compras.length) {
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

                    final compra =
                        state.compras[index];

                    final proveedor =
                        state.proveedorPorId(
                      compra.proveedorId,
                    );

                    final moto = compra.motoId == null
                        ? null
                        : state.motoPorId(
                            compra.motoId!,
                          );

                    final repuesto =
                        compra.repuestoId == null
                            ? null
                            : state.repuestoPorId(
                                compra.repuestoId!,
                              );

                    return _CompraCard(
                      compra: compra,
                      proveedorNombre: proveedor?.nombre ?? 'Desconocido',
                      productoNombre: moto != null
                          ? '${moto.marca.nombre} ${moto.modelo}'
                          : repuesto != null
                              ? '${repuesto.nombre} (${repuesto.sku})'
                              : compra.motoId != null
                                  ? 'Moto #${compra.motoId}'
                                  : 'Repuesto #${compra.repuestoId}',
                      tipoProducto: moto != null ||
                              compra.motoId != null
                          ? 'Moto'
                          : 'Repuesto',
                      canDelete: isAdmin,
                      onEdit: () {
                        showCompraForm(
                          context,
                          ref,
                          initial: compra,
                        );
                      },
                      onDelete: () {
                        _confirmDelete(
                          context,
                          compra,
                        );
                      },
                      onChangeState: (nuevoEstado) {
                        notifier.cambiarEstado(
                          compra.idCompra,
                          nuevoEstado,
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
    Compra compra,
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
            '¿Eliminar compra?',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'La compra #${compra.idCompra} se eliminará permanentemente.',
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
                      comprasAdminProvider.notifier,
                    )
                    .eliminarCompra(
                      compra.idCompra,
                    );

                if (!mounted) {
                  return;
                }

                final error = ref
                    .read(comprasAdminProvider)
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



class _EstadoCompraFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?>? onChanged;

  const _EstadoCompraFilter({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String?>(
      segments: const [
        ButtonSegment<String?>(
          value: null,
          label: Text(
            'Todas',
            maxLines: 1,
          ),
          icon: Icon(
            Icons.list_alt_outlined,
            size: 18,
          ),
        ),
        ButtonSegment<String?>(
          value: 'Pendiente',
          label: Text(
            'Pendientes',
            maxLines: 1,
          ),
          icon: Icon(
            Icons.schedule_outlined,
            size: 18,
          ),
        ),
        ButtonSegment<String?>(
          value: 'Recibida',
          label: Text(
            'Recibidas',
            maxLines: 1,
          ),
          icon: Icon(
            Icons.check_circle_outline,
            size: 18,
          ),
        ),
        ButtonSegment<String?>(
          value: 'Cancelada',
          label: Text(
            'Canceladas',
            maxLines: 1,
          ),
          icon: Icon(
            Icons.block_outlined,
            size: 18,
          ),
        ),
      ],
      selected: <String?>{selected},
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
            horizontal: 4,
          ),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 10,
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
      tooltip: 'Ordenar compras',
      color: AppColors.surface2,
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: '-fecha_compra',
          child: Text('Más recientes'),
        ),
        PopupMenuItem(
          value: 'fecha_compra',
          child: Text('Más antiguas'),
        ),
        PopupMenuItem(
          value: '-subtotal',
          child: Text('Mayor subtotal'),
        ),
        PopupMenuItem(
          value: 'subtotal',
          child: Text('Menor subtotal'),
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
          value: 'estado',
          child: Text('Estado A-Z'),
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
              'Ordenar compras',
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

class _CompraCard extends StatelessWidget {
  final Compra compra;
  final String proveedorNombre;
  final String productoNombre;
  final String tipoProducto;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onChangeState;

  const _CompraCard({
    required this.compra,
    required this.proveedorNombre,
    required this.productoNombre,
    required this.tipoProducto,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeState,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(
      compra.estado,
    );

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
                  'Compra #${compra.idCompra}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _CompraEstadoBadge(
                estado: compra.estado,
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Cambiar estado',
                color: AppColors.surface2,
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'editar') {
                    onEdit();
                    return;
                  }

                  if (value == 'eliminar') {
                    onDelete();
                    return;
                  }

                  onChangeState(value);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'Pendiente',
                    child: Text(
                      'Marcar como pendiente',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Recibida',
                    child: Text(
                      'Marcar como recibida',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Cancelada',
                    child: Text(
                      'Marcar como cancelada',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                  if (canDelete)
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Text(
                        'Eliminar',
                        style: TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          _CompraInfoRow(
            label: 'Proveedor',
            value: proveedorNombre,
          ),

          _CompraInfoRow(
            label: tipoProducto,
            value: productoNombre,
          ),

          _CompraInfoRow(
            label: 'Cantidad',
            value: compra.cantidad.toString(),
          ),

          _CompraInfoRow(
            label: 'Precio unitario',
            value:
                '\$ ${compra.precioUnitario.toStringAsFixed(2)}',
          ),

          _CompraInfoRow(
            label: 'Fecha',
            value: _formatDateTime(
              compra.fechaCompra,
            ),
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
                '\$ ${compra.subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: statusColor,
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

  static Color _statusColor(String estado) {
    switch (estado) {
      case 'Recibida':
        return AppColors.success;
      case 'Cancelada':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  static String _formatDateTime(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Sin fecha';
    }

    final local = date.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');
    final month =
        local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour =
        local.hour.toString().padLeft(2, '0');
    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _CompraInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompraInfoRow({
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
            width: 105,
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

class _CompraEstadoBadge extends StatelessWidget {
  final String estado;

  const _CompraEstadoBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      'Recibida' => AppColors.success,
      'Cancelada' => AppColors.error,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        estado,
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
            Icons.shopping_cart_checkout_outlined,
            color: AppColors.textFaint,
            size: 55,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'No se encontraron compras'
                : 'No existen compras registradas',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFilters
                ? 'Prueba con otros términos o estados.'
                : 'Registra la primera compra para comenzar.',
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