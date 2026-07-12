// lib/presentation/screens/catalog/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:motoshop_app/domain/model/categoria_moto.dart';
import 'package:motoshop_app/domain/model/marca.dart';
import '../../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/marca_form_dialog.dart';
import '../../widgets/categoria_form_dialog.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _motoScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _motoScrollController.addListener(_onMotoScroll);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _motoScrollController.removeListener(_onMotoScroll);
    _tabController.dispose();
    _motoScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _searchController.clear();
    // Reset search query on provider when tab changes
    if (_tabController.index == 0) {
      ref.read(motosProvider.notifier).setSearch('');
    } else if (_tabController.index == 1) {
      ref.read(marcasProvider.notifier).setSearch('');
    } else if (_tabController.index == 2) {
      ref.read(categoriasProvider.notifier).setSearch('');
    }
  }

  void _onMotoScroll() {
    if (_motoScrollController.position.pixels >= _motoScrollController.position.maxScrollExtent - 200) {
      ref.read(motosProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'administrador';
    final isVendedor = user?.role == 'vendedor';
    final canEdit = isAdmin || isVendedor || user?.isStaff == true;
    final canDelete = isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.motorcycle, color: AppColors.accent, size: 28),
            const SizedBox(width: 10),
            Text(
              'MotoShop',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.push('/inventory'),
            tooltip: 'Repuestos e Inventario',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            tooltip: 'Ver perfil',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.two_wheeler), text: 'Motos'),
            Tab(icon: Icon(Icons.branding_watermark), text: 'Marcas'),
            Tab(icon: Icon(Icons.category), text: 'Categorías'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMotosTab(canEdit),
          _buildMarcasTab(canEdit: canEdit, canDelete: canDelete),
          _buildCategoriasTab(canEdit: canEdit, canDelete: canDelete),
        ],
      ),
      floatingActionButton: _buildFAB(canEdit),
    );
  }

  // --- MOTOS TAB ---
  Widget _buildMotosTab(bool isStaff) {
    final state = ref.watch(motosProvider);

    return Column(
      children: [
        _buildSearchAndSortBar(
          hint: 'Buscar modelo, marca, categoría...',
          onSearch: (q) => ref.read(motosProvider.notifier).setSearch(q),
          showSort: true,
          currentSort: state.ordering,
          sortOptions: const {
            'modelo': 'Modelo (A-Z)',
            '-modelo': 'Modelo (Z-A)',
            'precio': 'Precio (Menor a Mayor)',
            '-precio': 'Precio (Mayor a Menor)',
            'anio': 'Año (Antiguas primero)',
            '-anio': 'Año (Nuevas primero)',
            'stock': 'Stock (Menor a Mayor)',
            '-stock': 'Stock (Mayor a Menor)',
          },
          onSortChanged: (val) {
            if (val != null) {
              ref.read(motosProvider.notifier).setOrdering(val);
            }
          },
        ),
        if (state.error != null)
          _buildErrorWidget(state.error!, () => ref.read(motosProvider.notifier).loadFirstPage()),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.motos.isEmpty
                  ? _buildEmptyState('No se encontraron motocicletas')
                  : RefreshIndicator(
                      onRefresh: () => ref.read(motosProvider.notifier).loadFirstPage(),
                      child: ListView.builder(
                        controller: _motoScrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.motos.length + (state.isMoreLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.motos.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final moto = state.motos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: InkWell(
                              onTap: () => context.push('/moto-detail/${moto.idMoto}'),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Moto Image Container
                                  Container(
                                    width: 120,
                                    height: 120,
                                    color: AppColors.surface,
                                    child: moto.imagen != null
                                        ? Image.network(
                                            moto.imagen!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) =>
                                                const Icon(Icons.image_not_supported, size: 40),
                                          )
                                        : const Icon(Icons.motorcycle_outlined, size: 50),
                                  ),
                                  // Details
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${moto.marca.nombre} ${moto.modelo}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: moto.stock > 0
                                                      ? AppColors.accent.withValues(alpha: 0.15)
                                                      : AppColors.error.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  moto.stock > 0 ? 'Stock: ${moto.stock}' : 'Agotado',
                                                  style: TextStyle(
                                                    color: moto.stock > 0
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
                                            'Categoría: ${moto.categoria.nombre}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Año: ${moto.anio}  ·  Cilindraje: ${moto.cilindraje} cc',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '\$${moto.precio.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: AppColors.accent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              Text(
                                                moto.estado.toUpperCase(),
                                                style: TextStyle(
                                                  color: moto.estado.toLowerCase() == 'activo' ||
                                                          moto.estado.toLowerCase() == 'disponible'
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // --- MARCAS TAB ---
  Widget _buildMarcasTab({required bool canEdit, required bool canDelete}) {
    final state = ref.watch(marcasProvider);

    return Column(
      children: [
        _buildSearchAndSortBar(
          hint: 'Buscar marcas...',
          onSearch: (q) => ref.read(marcasProvider.notifier).setSearch(q),
        ),
        if (state.error != null)
          _buildErrorWidget(state.error!, () => ref.read(marcasProvider.notifier).load()),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.marcas.isEmpty
                  ? _buildEmptyState('No se encontraron marcas')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.marcas.length,
                      itemBuilder: (context, index) {
                        final marca = state.marcas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.surface,
                              child: Text(
                                marca.nombre[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              marca.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(marca.descripcion ?? 'Sin descripción'),
                            trailing: canEdit
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _showMarcaDialog(marca),
                                      ),
                                      if (canDelete)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _confirmDeleteMarca(marca),
                                        ),
                                    ],
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: marca.estado
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      marca.estado ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        color: marca.estado ? Colors.green : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // --- CATEGORÍAS TAB ---
  Widget _buildCategoriasTab({required bool canEdit, required bool canDelete}) {
    final state = ref.watch(categoriasProvider);

    return Column(
      children: [
        _buildSearchAndSortBar(
          hint: 'Buscar categorías...',
          onSearch: (q) => ref.read(categoriasProvider.notifier).setSearch(q),
        ),
        if (state.error != null)
          _buildErrorWidget(state.error!, () => ref.read(categoriasProvider.notifier).load()),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.categorias.isEmpty
                  ? _buildEmptyState('No se encontraron categorías')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.categorias.length,
                      itemBuilder: (context, index) {
                        final categoria = state.categorias[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.surface,
                              child: Text(
                                categoria.nombre[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              categoria.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(categoria.descripcion ?? 'Sin descripción'),
                            trailing: canEdit
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _showCategoriaDialog(categoria),
                                      ),
                                      if (canDelete)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _confirmDeleteCategoria(categoria),
                                        ),
                                    ],
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: categoria.estado
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      categoria.estado ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        color: categoria.estado ? Colors.green : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // --- FLOATING ACTION BUTTON ---
  Widget? _buildFAB(bool canEdit) {
    if (!canEdit) return null;

    return FloatingActionButton(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      onPressed: () {
        if (_tabController.index == 0) {
          context.push('/moto-form');
        } else if (_tabController.index == 1) {
          _showMarcaDialog();
        } else if (_tabController.index == 2) {
          _showCategoriaDialog();
        }
      },
      child: const Icon(Icons.add),
    );
  }

  // --- WIDGETS DE APOYO ---
  Widget _buildSearchAndSortBar({
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

  // --- DIALOGS & UTILS ---
  void _showMarcaDialog([Marca? marca]) {
    showDialog(
      context: context,
      builder: (context) => MarcaFormDialog(marca: marca),
    ).then((updated) {
      if (updated == true) {
        ref.read(marcasProvider.notifier).load();
        ref.read(motosProvider.notifier).loadFirstPage();
      }
    });
  }

  void _showCategoriaDialog([CategoriaMoto? cat]) {
    showDialog(
      context: context,
      builder: (context) => CategoriaFormDialog(categoria: cat),
    ).then((updated) {
      if (updated == true) {
        ref.read(categoriasProvider.notifier).load();
        ref.read(motosProvider.notifier).loadFirstPage();
      }
    });
  }

  void _confirmDeleteMarca(Marca marca) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Marca'),
        content: Text('¿Estás seguro de que deseas eliminar la marca "${marca.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(marcasProvider.notifier).delete(marca.idMarca);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategoria(CategoriaMoto cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "${cat.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(categoriasProvider.notifier).delete(cat.idCategoria);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
