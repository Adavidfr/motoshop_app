// lib/presentation/providers/cart_provider.dart
//
// CartNotifier sincronizado con el backend real de Motoshop.
// Módulo 4: versión provisional con estado local.
// Módulo 5: sincronización con API /carritos/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/carrito_remote_datasource.dart';
import '../../domain/model/carrito.dart';
import '../../domain/model/product.dart';

// ── CartItem — ítem en memoria con producto completo ──────────────
class CartItem {
  final Product product;
  final int     quantity;
  final int?    idItem; // id del backend (null si aún no se sincronizó)

  const CartItem({
    required this.product,
    required this.quantity,
    this.idItem,
  });

  CartItem copyWith({int? quantity, int? idItem}) => CartItem(
    product:  product,
    quantity: quantity ?? this.quantity,
    idItem:   idItem   ?? this.idItem,
  );

  double get subtotal => product.price * quantity;
}

// ── CartState ──────────────────────────────────────────────────────
class CartState {
  final List<CartItem> items;
  final int?           carritoId;  // id del carrito en el backend
  final bool           isLoading;
  final String?        error;

  const CartState({
    this.items      = const [],
    this.carritoId,
    this.isLoading  = false,
    this.error,
  });

  int    get totalItems   => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal     => items.fold(0.0, (s, i) => s + i.subtotal);
  double get totalWithTax => items.fold(
    0.0,
    (s, i) => s + i.product.priceWithTax * i.quantity,
  );

  CartState copyWith({
    List<CartItem>? items,
    int?            carritoId,
    bool?           isLoading,
    String?         error,
    bool            clearError = false,
  }) => CartState(
    items:      items      ?? this.items,
    carritoId:  carritoId  ?? this.carritoId,
    isLoading:  isLoading  ?? this.isLoading,
    error:      clearError ? null : (error ?? this.error),
  );
}

// ── CartNotifier ───────────────────────────────────────────────────
class CartNotifier extends StateNotifier<CartState> {
  final CarritoRemoteDatasource _datasource;

  CartNotifier(this._datasource) : super(const CartState()) {
    _loadCarritoActivo();
  }

  /// Carga el carrito activo del usuario desde el backend.
  Future<void> _loadCarritoActivo() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final carrito = await _datasource.getCarritoActivo();
      _syncFromBackend(carrito);
    } catch (_) {
      // Sin carrito activo — estado vacío, sin error visible
      state = state.copyWith(isLoading: false, clearError: true);
    }
  }

  /// Sincroniza el estado local con la respuesta del backend.
  void _syncFromBackend(CarritoModel carrito) {
    // Los items del backend no tienen info del producto → los conservamos
    // si ya los teníamos; de lo contrario se muestran con datos mínimos.
    final backendItems = carrito.items;
    final newItems = backendItems.map((bi) {
      final existing = state.items.firstWhere(
        (i) =>
            (bi.idMoto     != null && i.product.idMoto     == bi.idMoto) ||
            (bi.idRepuesto != null && i.product.idRepuesto == bi.idRepuesto),
        orElse: () => CartItem(
          product: _placeholderProduct(bi),
          quantity: bi.cantidad,
          idItem: bi.idItem,
        ),
      );
      return existing.copyWith(quantity: bi.cantidad, idItem: bi.idItem);
    }).toList();

    state = state.copyWith(
      carritoId: carrito.idCarrito,
      items:     newItems,
      isLoading: false,
      clearError: true,
    );
  }

  /// Placeholder cuando el backend devuelve un item sin datos de producto.
  Product _placeholderProduct(ItemCarritoModel item) {
    final tipo = item.idMoto != null ? ProductType.moto : ProductType.repuesto;
    final id   = item.idMoto ?? item.idRepuesto ?? 0;
    return Product(
      id:    id,
      name:  tipo == ProductType.moto ? 'Moto #$id' : 'Repuesto #$id',
      price: item.precioUnitario,
      stock: 99,
      tipo:  tipo,
    );
  }

  /// Obtiene o crea el carrito activo en el backend y devuelve su id.
  Future<int> _getOrCreateCarritoId() async {
    if (state.carritoId != null) return state.carritoId!;
    try {
      final carrito = await _datasource.getCarritoActivo();
      state = state.copyWith(carritoId: carrito.idCarrito);
      return carrito.idCarrito;
    } catch (_) {
      final carrito = await _datasource.crearCarrito();
      state = state.copyWith(carritoId: carrito.idCarrito);
      return carrito.idCarrito;
    }
  }

  // ── Agregar ítem ──────────────────────────────────────────────
  Future<void> addItem(Product product, {int quantity = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final carritoId = await _getOrCreateCarritoId();
      final carrito   = await _datasource.addItem(
        carritoId:      carritoId,
        idMoto:         product.idMoto,
        idRepuesto:     product.idRepuesto,
        cantidad:       quantity,
        precioUnitario: product.price,
      );

      // Actualiza items del backend y conserva la info de producto
      final backendItems = carrito.items;
      final newItems = List<CartItem>.from(state.items);

      for (final bi in backendItems) {
        final idx = newItems.indexWhere(
          (i) =>
              (bi.idMoto     != null && i.product.idMoto     == bi.idMoto) ||
              (bi.idRepuesto != null && i.product.idRepuesto == bi.idRepuesto),
        );
        if (idx >= 0) {
          newItems[idx] = newItems[idx].copyWith(
            quantity: bi.cantidad,
            idItem:   bi.idItem,
          );
        } else {
          // Item nuevo — asignamos el product que ya tenemos
          newItems.add(CartItem(
            product:  product,
            quantity: bi.cantidad,
            idItem:   bi.idItem,
          ));
        }
      }

      state = state.copyWith(
        items:     newItems,
        carritoId: carrito.idCarrito,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Quitar ítem ───────────────────────────────────────────────
  Future<void> removeItem(int productId, ProductType tipo) async {
    final item = state.items.firstWhere(
      (i) => i.product.id == productId && i.product.tipo == tipo,
      orElse: () => throw Exception('Item no encontrado'),
    );
    if (item.idItem == null || state.carritoId == null) {
      // Solo local
      state = state.copyWith(
        items: state.items
            .where((i) => !(i.product.id == productId && i.product.tipo == tipo))
            .toList(),
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final carrito = await _datasource.removeItem(
        carritoId: state.carritoId!,
        itemId:    item.idItem!,
      );
      final remaining = state.items
          .where((i) => !(i.product.id == productId && i.product.tipo == tipo))
          .toList();
      state = state.copyWith(
        items:     remaining,
        carritoId: carrito.idCarrito,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Actualizar cantidad ───────────────────────────────────────
  Future<void> updateQuantity(
    int         productId,
    ProductType tipo,
    int         quantity,
  ) async {
    if (quantity <= 0) {
      await removeItem(productId, tipo);
      return;
    }
    // Actualización optimista
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.product.id == productId && i.product.tipo == tipo) {
          return i.copyWith(quantity: quantity);
        }
        return i;
      }).toList(),
    );
    // Sincronizar con backend: remove + add
    final carritoId = state.carritoId;
    if (carritoId == null) return;
    final item = state.items.firstWhere(
      (i) => i.product.id == productId && i.product.tipo == tipo,
    );
    if (item.idItem != null) {
      try {
        await _datasource.removeItem(carritoId: carritoId, itemId: item.idItem!);
        final carrito = await _datasource.addItem(
          carritoId:      carritoId,
          idMoto:         item.product.idMoto,
          idRepuesto:     item.product.idRepuesto,
          cantidad:       quantity,
          precioUnitario: item.product.price,
        );
        _syncFromBackend(carrito);
      } catch (_) {}
    }
  }

  // ── Vaciar carrito ────────────────────────────────────────────
  Future<void> clearCart() async {
    final carritoId = state.carritoId;
    if (carritoId == null) {
      state = const CartState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _datasource.vaciarCarrito(carritoId);
      state = CartState(carritoId: carritoId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Recarga el carrito desde el backend.
  Future<void> refresh() => _loadCarritoActivo();
}

// ── Provider ──────────────────────────────────────────────────────
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(carritoDatasourceProvider));
});
