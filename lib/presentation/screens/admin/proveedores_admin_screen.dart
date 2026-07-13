// lib/presentation/screens/admin/proveedores_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motoshop_app/presentation/providers/proveedor_admin_provider.dart';
import '../../providers/auth_provider.dart';

import '../../../domain/model/proveedor.dart';
import '../../../theme/app_colors.dart';

import '../../widgets/proveedor_form.dart';

class ProveedoresAdminScreen extends ConsumerStatefulWidget {
  const ProveedoresAdminScreen({
    super.key,
  });

  @override
  ConsumerState<ProveedoresAdminScreen> createState() {
    return _ProveedoresAdminScreenState();
  }
}

class _ProveedoresAdminScreenState
    extends ConsumerState<ProveedoresAdminScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    await ref
        .read(proveedoresAdminProvider.notifier)
        .setSearch(_searchController.text);
  }

  Future<void> _limpiarBusqueda() async {
    _searchController.clear();

    await ref
        .read(proveedoresAdminProvider.notifier)
        .setSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final state = ref.watch(proveedoresAdminProvider);
    final notifier = ref.read(
      proveedoresAdminProvider.notifier,
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
                        Text(
                          'Proveedores',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.total} proveedor${state.total == 1 ? '' : 'es'} registrado${state.total == 1 ? '' : 's'}',
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showProveedorForm(
                        context,
                        ref,
                      );
                    },
                    icon: Icon(
                      Icons.add,
                      size: 18,
                    ),
                    label: Text('Nuevo'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

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
                            'Buscar por nombre, contacto, correo o teléfono...',
                        prefixIcon: Icon(
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
                                    icon: Icon(
                                      Icons.close,
                                    ),
                                  ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),

                  SizedBox(width: 8),

                  IconButton.filled(
                    onPressed:
                        state.isLoading ? null : _buscar,
                    icon: Icon(
                      Icons.search,
                    ),
                    tooltip: 'Buscar',
                  ),
                ],
              ),

              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _EstadoFilter(
                      selected: state.filtroEstado,
                      onChanged: state.isLoading
                          ? null
                          : notifier.setFiltroEstado,
                    ),
                  ),

                  if (state.search.isNotEmpty ||
                      state.filtroEstado != null) ...[
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              _searchController.clear();
                              await notifier
                                  .limpiarFiltros();
                              setState(() {});
                            },
                      icon: Icon(
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
                  state.proveedores.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                );
              }

              if (state.error != null &&
                  state.proveedores.isEmpty) {
                return _ErrorView(
                  message: state.error!,
                  onRetry: notifier.load,
                );
              }

              if (state.proveedores.isEmpty) {
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
                      state.proveedores.length + 1,
                  separatorBuilder: (_, index) {
                    if (index ==
                        state.proveedores.length - 1) {
                      return SizedBox(height: 16);
                    }

                    return SizedBox(height: 10);
                  },
                  itemBuilder: (_, index) {
                    if (index ==
                        state.proveedores.length) {
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

                    final proveedor =
                        state.proveedores[index];

                    return _ProveedorCard(
                      proveedor: proveedor,
                      canDelete: isAdmin,
                      onToggle: () {
                        notifier.toggleEstado(
                          proveedor.id,
                          !proveedor.estado,
                        );
                      },
                      onEdit: () {
                        showProveedorForm(
                          context,
                          ref,
                          initial: proveedor,
                        );
                      },
                      onDelete: () {
                        _confirmDelete(
                          context,
                          proveedor,
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
    Proveedor proveedor,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '¿Eliminar proveedor?',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            '"${proveedor.nombre}" se eliminará permanentemente.\n\n'
            'Si tiene compras relacionadas, el backend podría impedir la eliminación. En ese caso puedes desactivarlo.',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await ref
                    .read(
                      proveedoresAdminProvider.notifier,
                    )
                    .eliminarProveedor(proveedor.id);

                if (!mounted) {
                  return;
                }

                final error = ref
                    .read(proveedoresAdminProvider)
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
              child: Text(
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
          label: Text('Todos'),
          icon: Icon(Icons.list_alt_outlined),
        ),
        ButtonSegment<bool?>(
          value: true,
          label: Text('Activos'),
          icon: Icon(Icons.check_circle_outline),
        ),
        ButtonSegment<bool?>(
          value: false,
          label: Text('Inactivos'),
          icon: Icon(Icons.block_outlined),
        ),
      ],
      selected: <bool?>{selected},
      onSelectionChanged: onChanged == null
          ? null
          : (values) {
              onChanged!(values.first);
            },
      showSelectedIcon: false,
      style: ButtonStyle(
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
          BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _ProveedorCard extends StatelessWidget {
  final Proveedor proveedor;
  final bool canDelete;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProveedorCard({
    required this.proveedor,
    required this.canDelete,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: proveedor.estado ? 1 : 0.58,
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
              value: proveedor.estado,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.accent,
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

            SizedBox(width: 4),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          proveedor.nombre,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      _EstadoBadge(
                        activo: proveedor.estado,
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  if (_tieneTexto(
                    proveedor.contacto,
                  ))
                    _InfoRow(
                      icon: Icons.person_outline,
                      text: proveedor.contacto!,
                    ),

                  if (_tieneTexto(
                    proveedor.telefono,
                  ))
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      text: proveedor.telefono!,
                    ),

                  if (_tieneTexto(
                    proveedor.correo,
                  ))
                    _InfoRow(
                      icon: Icons.email_outlined,
                      text: proveedor.correo!,
                    ),

                  if (_tieneTexto(
                    proveedor.direccion,
                  ))
                    _InfoRow(
                      icon:
                          Icons.location_on_outlined,
                      text: proveedor.direccion!,
                      maxLines: 2,
                    ),

                  if (!_tieneTexto(
                        proveedor.contacto,
                      ) &&
                      !_tieneTexto(
                        proveedor.telefono,
                      ) &&
                      !_tieneTexto(
                        proveedor.correo,
                      ) &&
                      !_tieneTexto(
                        proveedor.direccion,
                      ))
                    Text(
                      'Sin información de contacto',
                      style: TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(width: 6),

            Column(
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
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
                    icon: Icon(
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
    return value != null && value.trim().isNotEmpty;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
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
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ||
                          !hasPrevious
                      ? null
                      : onPrevious,
                  icon: Icon(
                    Icons.chevron_left,
                  ),
                  label: Text('Anterior'),
                ),
              ),

              SizedBox(width: 10),

              DropdownButton<int>(
                value: pageSize,
                dropdownColor: AppColors.surface2,
                style: TextStyle(
                  color: AppColors.textPrimary,
                ),
                underline: SizedBox.shrink(),
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

              SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading || !hasNext
                          ? null
                          : onNext,
                  icon: Icon(
                    Icons.chevron_right,
                  ),
                  label: Text('Siguiente'),
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
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Reintentar'),
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
          Icon(
            Icons.local_shipping_outlined,
            color: AppColors.textFaint,
            size: 55,
          ),
          SizedBox(height: 12),
          Text(
            hasFilters
                ? 'No se encontraron proveedores'
                : 'No existen proveedores registrados',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            hasFilters
                ? 'Prueba con otros términos o filtros.'
                : 'Registra el primer proveedor para comenzar.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}