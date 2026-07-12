// lib/presentation/providers/orders_client_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/order_remote_datasource.dart';
import '../../data/remote/api/venta_remote_datasource.dart';
import '../../domain/model/order.dart';
import '../../domain/model/venta.dart';

class OrdersClientState {
  final List<Order> orders;
  final bool        isLoading;
  final String?     error;

  const OrdersClientState({
    this.orders    = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersClientState copyWith({
    List<Order>? orders,
    bool?        isLoading,
    String?      error,
  }) => OrdersClientState(
    orders:    orders ?? this.orders,
    isLoading: isLoading ?? this.isLoading,
    error:     error,
  );
}

class OrdersClientNotifier extends StateNotifier<OrdersClientState> {
  final OrderRemoteDatasource _datasource;

  OrdersClientNotifier(this._datasource) : super(const OrdersClientState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _datasource.getOrders(page: 1); // Client orders
      state = state.copyWith(
        orders:    result.results,
        isLoading: false,
        error:     null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> checkout(int carritoId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _datasource.createOrder(carritoId);
      await load();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final ordersClientProvider =
    StateNotifierProvider<OrdersClientNotifier, OrdersClientState>((ref) {
  return OrdersClientNotifier(ref.watch(orderDatasourceProvider));
});

// Provider del detalle de pedido (cliente)
final orderClientDetailProvider = FutureProvider.family<Order, int>((ref, id) {
  return ref.watch(orderDatasourceProvider).getOrder(id);
});

// Provider de financiamientos del cliente (a través de sus ventas)
final clientFinanciamientosProvider = FutureProvider<List<Financiamiento>>((ref) async {
  final result = await ref.read(ventaDatasourceProvider).getVentas(page: 1);
  final List<Financiamiento> list = [];
  for (final venta in result.results) {
    list.addAll(venta.financiamientos);
  }
  return list;
});

