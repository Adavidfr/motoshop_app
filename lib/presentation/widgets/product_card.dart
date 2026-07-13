// lib/presentation/widgets/product_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/model/product.dart';

class ProductCard extends StatelessWidget {
  final Product      product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: AppColors.accent.withOpacity(0.12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color:       AppColors.accent.withOpacity(0.04),
              blurRadius:  10,
              spreadRadius: 1,
              offset:      const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            // ── Imagen ────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit:         BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(color: AppColors.surface2);
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const _ImagePlaceholder(),
                            )
                          : const _ImagePlaceholder(),
                    ),
                  ),
                  if (!product.inStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ──────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipo / Categoría
                        Row(
                          children: [
                            Text(
                              product.tipo == ProductType.moto ? '🏍️' : '🔧',
                              style: TextStyle(fontSize: 10),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (product.category?.name ??
                                    (product.tipo == ProductType.moto
                                        ? 'MOTO'
                                        : 'REPUESTO'))
                                    .toUpperCase(),
                                style: TextStyle(
                                  color:         AppColors.accent,
                                  fontSize:      9,
                                  fontWeight:    FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),

                        // Nombre
                        Text(
                          product.name,
                          style: TextStyle(
                            color:      AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize:   13,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Precios
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatPrice(product.priceWithTax),
                          style: TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize:   15,
                          ),
                        ),
                        Text(
                          '${formatPrice(product.price)} sin IVA',
                          style: TextStyle(
                            color:    AppColors.textSecondary,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color:     AppColors.surface2,
    alignment: Alignment.center,
    child: Icon(Icons.two_wheeler_rounded, color: AppColors.textFaint, size: 48),
  );
}
