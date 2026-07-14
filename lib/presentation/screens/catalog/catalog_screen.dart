// lib/presentation/screens/catalog/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filters_sheet.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(catalogProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final state      = ref.read(catalogProvider);
    final notifier   = ref.read(catalogProvider.notifier);
    final categories = state.categories;

    final filters = await showFiltersSheet(
      context: context,
      activeFilters: ProductFilters(
        categoryId: state.categoryId,
        minPrice:   state.minPrice,
        maxPrice:   state.maxPrice,
        ordering:   state.ordering,
      ),
      categories: categories,
    );

    if (filters != null) {
      notifier.setCategory(filters.categoryId);
      notifier.setPriceRange(filters.minPrice, filters.maxPrice);
      notifier.setOrdering(filters.ordering);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(catalogProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final tt        = Theme.of(context).textTheme;

    final hasActiveFilters = state.categoryId != null ||
        state.minPrice != null ||
        state.maxPrice != null ||
        (state.ordering != null && state.ordering!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              color:   AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Catálogo',
                          style: tt.headlineMedium
                              ?.copyWith(color: AppColors.textPrimary)),
                      Text(
                        '${state.total} productos',
                        style: tt.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Barra de búsqueda + botón filtros
                  Row(
                    children: [
                      Expanded(
                        child: SearchBarWidget(
                          initialValue: state.search,
                          hintText:     'Buscar motos o repuestos...',
                          onChanged: (q) =>
                              ref.read(catalogProvider.notifier).setSearch(q),
                        ),
                      ),
                      SizedBox(width: 8),
                      Badge(
                        isLabelVisible: hasActiveFilters,
                        backgroundColor: AppColors.accent,
                        child: IconButton(
                          onPressed: _openFilters,
                          tooltip: 'Filtros',
                          icon: Icon(
                            Icons.tune_rounded,
                            color: hasActiveFilters
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Chips de ordenamiento
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final item in [
                          (null,         'Relevancia'),
                          ('price',      'Precio ↑'),
                          ('-price',     'Precio ↓'),
                          ('-created_at','Recientes'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item.$2),
                              selected: state.ordering == item.$1,
                              onSelected: (_) => ref
                                  .read(catalogProvider.notifier)
                                  .setOrdering(item.$1),
                              selectedColor:    AppColors.accent,
                              labelStyle: TextStyle(
                                color: state.ordering == item.$1
                                    ? AppColors.onAccent
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Chips de categorías
                  catsAsync.when(
                    loading: () => SizedBox.shrink(),
                    error:   (_, __) => SizedBox.shrink(),
                    data: (cats) => SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label:     Text('Todas'),
                              selected:  state.categoryId == null,
                              onSelected: (_) => ref
                                  .read(catalogProvider.notifier)
                                  .setCategory(null),
                              selectedColor: AppColors.accent,
                              labelStyle: TextStyle(
                                color: state.categoryId == null
                                    ? AppColors.onAccent
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          for (final cat in cats.where((c) => c.isActive))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label:     Text(cat.name),
                                selected:  state.categoryId == cat.id,
                                onSelected: (_) => ref
                                    .read(catalogProvider.notifier)
                                    .setCategory(cat.id),
                                selectedColor: AppColors.accent,
                                labelStyle: TextStyle(
                                  color: state.categoryId == cat.id
                                      ? AppColors.onAccent
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),

            // ── Grid de productos ────────────────────────────
            Expanded(
              child: Builder(
                builder: (_) {
                  if (state.isLoading && state.products.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }
                  if (state.error != null && state.products.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('❌',
                                style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text(state.error!,
                                style: TextStyle(
                                    color: AppColors.error),
                                textAlign: TextAlign.center),
                            SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => ref
                                  .read(catalogProvider.notifier)
                                  .refresh(),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.onAccent,
                              ),
                              child: Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🔍', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('Sin resultados',
                              style: TextStyle(
                                color:      AppColors.textPrimary,
                                fontSize:   18,
                                fontWeight: FontWeight.bold,
                              )),
                          Text('Intenta con otra búsqueda',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(catalogProvider.notifier).refresh(),
                    color: AppColors.accent,
                    child: GridView.builder(
                      controller:  _scrollCtrl,
                      padding:     const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:   2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing:  12,
                        childAspectRatio: 0.61,
                      ),
                      itemCount: state.products.length +
                          (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= state.products.length) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color:       AppColors.accent,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        final product = state.products[i];
                        return ProductCard(
                          product: product,
                          onTap: () => context.push(
                            '/catalog/${product.tipo.name}/${product.id}',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
