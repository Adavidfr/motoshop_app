// lib/presentation/screens/inventory/inventory_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_providers.dart';

class InventoryDashboardScreen extends ConsumerStatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  ConsumerState<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends ConsumerState<InventoryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _repuestoScroll = ScrollController();
  final ScrollController _movimientoScroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repuestoScroll.addListener(_onRepuestoScroll);
    _movimientoScroll.addListener(_onMovimientoScroll);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _repuestoScroll.removeListener(_onRepuestoScroll);
    _movimientoScroll.removeListener(_onMovimientoScroll);
    _tabController.dispose();
    _repuestoScroll.dispose();
    _movimientoScroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _searchController.clear();
    if (_tabController.index == 0) {
      ref.read(repuestosProvider.notifier).setSearch('');
    } else {
      ref.read(movimientosProvider.notifier).setSearch('');
    }
  }

  void _onRepuestoScroll() {
    if (_repuestoScroll.position.pixels >= _repuestoScroll.position.maxScrollExtent - 200) {
      ref.read(repuestosProvider.notifier).loadNextPage();
    }
  }

  void _onMovimientoScroll() {
    if (_movimientoScroll.position.pixels >= _movimientoScroll.position.maxScrollExtent - 200) {
      ref.read(movimientosProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final isVendedor = user?.role == 'vendedor';
    final canEdit = isAdmin || isVendedor || user?.isStaff == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repuestos e Inventario'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.build_outlined), text: 'Repuestos'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Movimientos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRepuestosTab(canEdit),
          _buildMovimientosTab(canEdit),
        ],
      ),
      floatingActionButton: _buildFAB(canEdit),
    );
  }

  // --- REPUESTOS TAB ---
  Widget _buildRepuestosTab(bool canEdit) {
    final state = ref.watch(repuestosProvider);

    return Column(
      children: [
        _buildSearchBar(
          hint: 'Buscar repuesto por nombre, sku...',
          onSearch: (q) => ref.read(repuestosProvider.notifier).setSearch(q),
          showSort: true,
          currentSort: state.ordering,
          sortOptions: const {
            'nombre': 'Nombre (A-Z)',
            '-nombre': 'Nombre (Z-A)',
            'precio_venta': 'Precio de Venta (Menor a Mayor)',
            '-precio_venta': 'Precio de Venta (Mayor a Menor)',
            'costo': 'Costo (Menor a Mayor)',
            '-costo': 'Costo (Mayor a Menor)',
            'stock': 'Stock (Menor a Mayor)',
            '-stock': 'Stock (Mayor a Menor)',
          },
          onSortChanged: (val) {
            if (val != null) {
              ref.read(repuestosProvider.notifier).setOrdering(val);
            }
          },
        ),
        if (state.error != null)
          _buildErrorWidget(state.error!, () => ref.read(repuestosProvider.notifier).loadFirstPage()),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.repuestos.isEmpty
                  ? _buildEmptyState('No se encontraron repuestos')
                  : RefreshIndicator(
                      onRefresh: () => ref.read(repuestosProvider.notifier).loadFirstPage(),
                      child: ListView.builder(
                        controller: _repuestoScroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.repuestos.length + (state.isMoreLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.repuestos.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final repuesto = state.repuestos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            clipBehavior: Clip.antiAlias,
                            elevation: 3,
                            child: InkWell(
                              onTap: () => context.push('/repuesto-detail/${repuesto.idRepuesto}'),
                              child: Row(
                                children: [
                                  // Image
                                  Container(
                                    width: 100,
                                    height: 100,
                                    color: AppColors.surface,
                                    child: repuesto.imagen != null
                                        ? Image.network(
                                            repuesto.imagen!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) =>
                                                const Icon(Icons.broken_image_outlined, size: 30),
                                          )
                                        : const Icon(Icons.settings_outlined, size: 40),
                                  ),
                                  // Detail
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  repuesto.nombre,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold, fontSize: 15),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: repuesto.stock > 0
                                                      ? AppColors.accent.withValues(alpha: 0.15)
                                                      : AppColors.error.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Stock: ${repuesto.stock}',
                                                  style: TextStyle(
                                                    color: repuesto.stock > 0
                                                        ? AppColors.accent
                                                        : AppColors.error,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'SKU: ${repuesto.sku}',
                                            style: const TextStyle(
                                                fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '\$${repuesto.precioVenta.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: AppColors.accent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                repuesto.estado.toUpperCase(),
                                                style: TextStyle(
                                                  color: repuesto.estado.toLowerCase() == 'activo'
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        )
      ],
    );
  }

  // --- MOVIMIENTOS TAB ---
  Widget _buildMovimientosTab(bool canEdit) {
    final state = ref.watch(movimientosProvider);

    return Column(
      children: [
        _buildSearchBar(
          hint: 'Buscar movimientos...',
          onSearch: (q) => ref.read(movimientosProvider.notifier).setSearch(q),
        ),
        if (state.error != null)
          _buildErrorWidget(state.error!, () => ref.read(movimientosProvider.notifier).loadFirstPage()),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.movimientos.isEmpty
                  ? _buildEmptyState('No hay movimientos registrados')
                  : RefreshIndicator(
                      onRefresh: () => ref.read(movimientosProvider.notifier).loadFirstPage(),
                      child: ListView.builder(
                        controller: _movimientoScroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.movimientos.length + (state.isMoreLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.movimientos.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final mov = state.movimientos[index];
                          final isEntrada = mov.tipoMovimiento.toLowerCase() == 'entrada';
                          final affectedItem = mov.moto != null
                              ? 'Moto: ${mov.moto!.marca.nombre} ${mov.moto!.modelo}'
                              : (mov.repuesto != null
                                  ? 'Repuesto: ${mov.repuesto!.nombre}'
                                  : 'N/A');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isEntrada
                                              ? Colors.green.withValues(alpha: 0.15)
                                              : Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          mov.tipoMovimiento.toUpperCase(),
                                          style: TextStyle(
                                            color: isEntrada ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Cant: ${mov.cantidad}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    affectedItem,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (mov.descripcion != null && mov.descripcion!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      mov.descripcion!,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            mov.usuario.username,
                                            style: const TextStyle(
                                                fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        mov.fechaMovimiento.split('T')[0],
                                        style: const TextStyle(
                                            fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        )
      ],
    );
  }

  // --- FLOATING ACTION BUTTON ---
  Widget? _buildFAB(bool canEdit) {
    // Both Spare parts and inventory actions are for staff.
    if (!canEdit) return null;

    return FloatingActionButton.extended(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      onPressed: () {
        if (_tabController.index == 0) {
          context.push('/repuesto-form');
        } else {
          context.push('/movimiento-form');
        }
      },
      icon: Icon(_tabController.index == 0 ? Icons.add : Icons.swap_horiz),
      label: Text(_tabController.index == 0 ? 'Nuevo Repuesto' : 'Reg. Movimiento'),
    );
  }

  // --- WIDGETS DE APOYO ---
  Widget _buildSearchBar({
    required String hint,
    required ValueChanged<String> onSearch,
    bool showSort = false,
    String? currentSort,
    Map<String, String>? sortOptions,
    ValueChanged<String?>? onSortChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    onSearch('');
                  },
                ),
              ),
              onChanged: onSearch,
            ),
          ),
          if (showSort && sortOptions != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentSort,
                  icon: const Icon(Icons.sort, color: AppColors.accent),
                  onChanged: onSortChanged,
                  items: sortOptions.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
