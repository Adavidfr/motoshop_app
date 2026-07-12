// lib/presentation/screens/catalog/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final catalogState    = ref.watch(catalogProvider);
    final tt              = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width:   double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [
                    Color(0xFF280305), // Rojo carbón metálico
                    Color(0xFF0F0102),
                    Color(0xFF000000), // Negro
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'TEMPORADA 2026',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo_circular.jpg',
                        height: 38,
                        width: 38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Descubre tu',
                    style: tt.headlineLarge?.copyWith(
                      color:      AppColors.textSecondary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    'AuraRider',
                    style: tt.displaySmall?.copyWith(
                      color:      Colors.white,
                      fontWeight: FontWeight.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Motos exclusivas e inventario de repuestos de alto rendimiento.',
                    style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: () => context.go('/catalog'),
                      icon:      const Icon(Icons.two_wheeler_rounded, size: 18),
                      label:     const Text('Explorar Catálogo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Categorías ────────────────────────────────────
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (cats) {
                final active = cats.where((c) => c.isActive).take(6).toList();
                if (active.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Categorías',
                              style: tt.titleLarge?.copyWith(
                                  color: AppColors.textPrimary)),
                          TextButton(
                            onPressed: () => context.go('/catalog'),
                            child: const Text('Ver todas',
                                style: TextStyle(color: AppColors.accent)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        padding:         const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount:       active.length,
                        separatorBuilder:(_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final cat = active[i];
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(catalogProvider.notifier)
                                  .setCategory(cat.id);
                              context.go('/catalog');
                            },
                            child: Container(
                              width:   110,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:        AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border:       Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🏷️',
                                      style: TextStyle(fontSize: 22)),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      color:      AppColors.textPrimary,
                                      fontSize:   11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines:  1,
                                    overflow:  TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),

          // ── Novedades — encabezado ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Novedades',
                    style: tt.titleLarge?.copyWith(color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => context.go('/catalog'),
                    child: const Text('Ver todos',
                        style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            ),
          ),

          // ── Novedades — grid ───────────────────────────────
          if (catalogState.isLoading && catalogState.products.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child:   CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final products = catalogState.products.take(4).toList();
                    final product  = products[i];
                    return ProductCard(
                      product: product,
                      onTap: () => context.push(
                        '/catalog/${product.tipo.name}/${product.id}',
                      ),
                    );
                  },
                  childCount: catalogState.products.take(4).length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing:  12,
                  childAspectRatio: 0.65,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
