// lib/presentation/screens/cart/cart_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/model/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_client_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final notifier  = ref.read(cartProvider.notifier);
    final tt        = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation:       0,
        title: Text(
          'Mi Carrito',
          style: tt.titleLarge?.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: cartState.isLoading ? null : () async {
                final confirm = await _confirmDialog(context);
                if (confirm == true && context.mounted) {
                  await notifier.clearCart();
                }
              },
              child: const Text(
                'Vaciar',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: cartState.isLoading && cartState.items.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : cartState.items.isEmpty
              ? _EmptyCart(onShop: () => context.go('/catalog'))
              : Column(
                  children: [
                    // ── Lista de ítems ───────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: notifier.refresh,
                        color:     AppColors.accent,
                        child: ListView.separated(
                          padding:         const EdgeInsets.all(16),
                          itemCount:       cartState.items.length,
                          separatorBuilder:(_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = cartState.items[i];
                            return _CartItemTile(
                              item:      item,
                              isLoading: cartState.isLoading,
                              onRemove:  () => notifier.removeItem(
                                item.product.id,
                                item.product.tipo,
                              ),
                              onDecrement: () => notifier.updateQuantity(
                                item.product.id,
                                item.product.tipo,
                                item.quantity - 1,
                              ),
                              onIncrement: () => notifier.updateQuantity(
                                item.product.id,
                                item.product.tipo,
                                item.quantity + 1,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Resumen del pedido ───────────────────
                    _OrderSummary(
                      cartState: cartState,
                      tt:        tt,
                      onCheckout: () => _checkout(context, ref),
                    ),
                  ],
                ),
    );
  }

  Future<bool?> _confirmDialog(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Vaciar carrito',
          style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('¿Seguro que deseas eliminar todos los ítems?',
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Vaciar'),
        ),
      ],
    ),
  );

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final cartState = ref.read(cartProvider);
    final carritoId = cartState.carritoId;
    if (carritoId == null || cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('El carrito está vacío'),
          backgroundColor: AppColors.error,
          behavior:        SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // 1. Crear el pedido en el backend
      await ref.read(ordersClientProvider.notifier).checkout(carritoId);

      // 2. Reiniciar el estado local del carrito
      ref.read(cartProvider.notifier).resetCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('¡Pedido confirmado exitosamente!'),
            backgroundColor: AppColors.success,
            behavior:        SnackBarBehavior.floating,
          ),
        );
        context.go('/orders');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Error al confirmar pedido: $e'),
            backgroundColor: AppColors.error,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Tile de un ítem en el carrito ─────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem    item;
  final bool        isLoading;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartItemTile({
    required this.item,
    required this.isLoading,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Imagen
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width:  90,
              height: 90,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl:    product.imageUrl!,
                      fit:         BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surface2),
                      errorWidget: (_, __, ___) => _TileNoImage(product),
                    )
                  : _TileNoImage(product),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color:      AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize:   14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(product.price),
                    style: const TextStyle(
                      color:   AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Controles de cantidad
                  Row(
                    children: [
                      _SmallBtn(
                        icon:     Icons.remove,
                        onTap:    isLoading ? null : onDecrement,
                        enabled:  item.quantity > 1,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color:  AppColors.surface2,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(
                            color:      AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _SmallBtn(
                        icon:    Icons.add,
                        onTap:   isLoading ? null : onIncrement,
                        enabled: item.quantity < product.stock,
                      ),
                      const Spacer(),
                      // Subtotal
                      Text(
                        formatPrice(item.subtotal),
                        style: const TextStyle(
                          color:      AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize:   14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Botón eliminar
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon:      const Icon(Icons.delete_outline, size: 20),
              color:     AppColors.error,
              onPressed: isLoading ? null : onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData   icon;
  final VoidCallback? onTap;
  final bool       enabled;
  const _SmallBtn({required this.icon, this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width:  28,
      height: 28,
      decoration: BoxDecoration(
        color:  AppColors.surface2,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        icon,
        size:  14,
        color: enabled ? AppColors.textPrimary : AppColors.textFaint,
      ),
    ),
  );
}

class _TileNoImage extends StatelessWidget {
  final Product product;
  const _TileNoImage(this.product);

  @override
  Widget build(BuildContext context) => Container(
    color:     AppColors.surface2,
    alignment: Alignment.center,
    child: Text(
      product.tipo == ProductType.moto ? '🏍️' : '🔧',
      style: const TextStyle(fontSize: 28),
    ),
  );
}

// ── Panel de resumen ──────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final CartState    cartState;
  final TextTheme    tt;
  final VoidCallback onCheckout;

  const _OrderSummary({
    required this.cartState,
    required this.tt,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color:  AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (sin IVA)',
                  style: const TextStyle(color: AppColors.textSecondary)),
              Text(formatPrice(cartState.subtotal),
                  style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total con IVA (12%)',
                  style: const TextStyle(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize:   16,
                  )),
              Text(
                formatPrice(cartState.totalWithTax),
                style: const TextStyle(
                  color:      AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize:   18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: cartState.isLoading ? null : onCheckout,
              icon:      const Icon(Icons.check_circle_outline),
              label:     const Text('Confirmar pedido'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                minimumSize:     const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carrito vacío ─────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🛒', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text(
          'Tu carrito está vacío',
          style: TextStyle(
            color:      AppColors.textPrimary,
            fontSize:   20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Agrega motos o repuestos al carrito',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onShop,
          icon:      const Icon(Icons.grid_view_rounded),
          label:     const Text('Ir al catálogo'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    ),
  );
}
