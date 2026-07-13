// lib/presentation/screens/catalog/product_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/model/product.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int         productId;
  final ProductType tipo;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.tipo,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(
      productDetailProvider(
          (id: widget.productId, tipo: widget.tipo)),
    );
    final cartState = ref.watch(cartProvider);
    final tt        = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor:  AppColors.surface,
        foregroundColor:  AppColors.textPrimary,
        elevation:        0,
        leading:          IconButton(
          icon:      Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.tipo == ProductType.moto ? 'Moto' : 'Repuesto',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon:      Icon(Icons.shopping_cart_outlined),
                color:     AppColors.textPrimary,
                onPressed: () => context.push('/cart'),
              ),
              if (cartState.totalItems > 0)
                Positioned(
                  right: 6,
                  top:   6,
                  child: Container(
                    padding:    const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cartState.totalItems.toString(),
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('❌', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text(err.toString(),
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center),
              SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(
                  productDetailProvider(
                      (id: widget.productId, tipo: widget.tipo)),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                ),
                child: Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (product) => _ProductBody(
          product:  product,
          quantity: _quantity,
          onQtyChanged: (q) => setState(() => _quantity = q),
          tt: tt,
        ),
      ),
    );
  }
}

class _ProductBody extends ConsumerWidget {
  final Product  product;
  final int      quantity;
  final void Function(int) onQtyChanged;
  final TextTheme tt;

  const _ProductBody({
    required this.product,
    required this.quantity,
    required this.onQtyChanged,
    required this.tt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState    = ref.watch(cartProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagen ─────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl:    product.imageUrl!,
                    fit:         BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surface2),
                    errorWidget: (_, __, ___) => _NoImage(product),
                  )
                : _NoImage(product),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:       Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    product.tipo == ProductType.moto
                        ? '🏍️ Moto'
                        : '🔧 Repuesto',
                    style: TextStyle(
                      color:      AppColors.accent,
                      fontSize:   12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Nombre
                Text(
                  product.name,
                  style: tt.headlineSmall?.copyWith(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                // Categoría
                if (product.category != null)
                  Text(
                    product.category!.name,
                    style: TextStyle(
                      color:   AppColors.accent,
                      fontSize: 13,
                    ),
                  ),

                // Campos extra según tipo
                if (product.tipo == ProductType.moto) ...[
                  SizedBox(height: 12),
                  _InfoRow('Marca',      product.marca     ?? '—'),
                  _InfoRow('Año',        product.anio?.toString() ?? '—'),
                  _InfoRow('Cilindraje', '${product.cilindraje} cc'),
                  _InfoRow('Color',      product.color     ?? '—'),
                ] else if (product.sku != null) ...[
                  SizedBox(height: 12),
                  _InfoRow('SKU', product.sku!),
                ],

                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Descripción',
                    style: tt.titleSmall?.copyWith(
                        color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.description!,
                    style: TextStyle(
                      color:  AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],

                SizedBox(height: 24),
                Divider(color: AppColors.border),
                SizedBox(height: 16),

                // ── Precio ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(product.price),
                      style: tt.headlineMedium?.copyWith(
                        color:      AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${formatPrice(product.priceWithTax)} c/IVA',
                        style: TextStyle(
                          color:   AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Stock
                Row(
                  children: [
                    Icon(
                      product.inStock
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: product.inStock
                          ? AppColors.success
                          : AppColors.error,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      product.inStock
                          ? '${product.stock} en stock'
                          : 'Sin stock',
                      style: TextStyle(
                        color: product.inStock
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // ── Selector de cantidad ──────────────────────
                if (product.inStock) ...[
                  Text(
                    'Cantidad',
                    style: tt.titleSmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyButton(
                        icon:      Icons.remove,
                        onPressed: quantity > 1
                            ? () => onQtyChanged(quantity - 1)
                            : null,
                      ),
                      Container(
                        width:   52,
                        height:  40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                                color: AppColors.border),
                          ),
                          color: AppColors.surface2,
                        ),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            color:      AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize:   16,
                          ),
                        ),
                      ),
                      _QtyButton(
                        icon:      Icons.add,
                        onPressed: quantity < product.stock
                            ? () => onQtyChanged(quantity + 1)
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],

                // ── Botón Agregar al carrito ──────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: product.inStock && !cartState.isLoading
                        ? () async {
                            await cartNotifier.addItem(
                              product,
                              quantity: quantity,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} agregado al carrito',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label:     'Ver carrito',
                                    textColor: Colors.white,
                                    onPressed: () => context.push('/cart'),
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    icon: cartState.isLoading
                        ? SizedBox(
                            width:  16,
                            height: 16,
                            child:  CircularProgressIndicator(
                              color:       Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      product.inStock
                          ? 'Agregar al carrito'
                          : 'Sin stock',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: product.inStock
                          ? AppColors.accent
                          : AppColors.border,
                      foregroundColor: product.inStock
                          ? AppColors.onAccent
                          : AppColors.textSecondary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (cartState.error != null) ...[
                  SizedBox(height: 12),
                  Text(
                    cartState.error!,
                    style: TextStyle(
                        color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],

                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color:   AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:      AppColors.textPrimary,
            fontSize:   13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _QtyButton extends StatelessWidget {
  final IconData    icon;
  final VoidCallback? onPressed;
  const _QtyButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
    color:  AppColors.surface2,
    shape:  RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0),
      side:         BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onPressed,
      child: SizedBox(
        width:  40,
        height: 40,
        child:  Icon(
          icon,
          size:  18,
          color: onPressed != null
              ? AppColors.textPrimary
              : AppColors.textFaint,
        ),
      ),
    ),
  );
}

class _NoImage extends StatelessWidget {
  final Product product;
  const _NoImage(this.product);

  @override
  Widget build(BuildContext context) => Container(
    color:     AppColors.surface2,
    alignment: Alignment.center,
    child: Text(
      product.tipo == ProductType.moto ? '🏍️' : '🔧',
      style: TextStyle(fontSize: 64),
    ),
  );
}
