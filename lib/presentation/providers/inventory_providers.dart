// lib/presentation/providers/inventory_providers.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/inventory_remote_datasource.dart';
import '../../domain/model/repuesto.dart';
import '../../domain/model/movimiento_inventario.dart';
import 'catalog_providers.dart'; // We can invalidate motosProvider to refresh stock on movements

// ── Estado de Formulario Genérico para Inventario ────────────────
sealed class InventoryFormState { const InventoryFormState(); }
class InventoryFormIdle extends InventoryFormState { const InventoryFormIdle(); }
class InventoryFormSaving extends InventoryFormState { const InventoryFormSaving(); }
class InventoryFormSuccess extends InventoryFormState {
  final String message;
  const InventoryFormSuccess(this.message);
}
class InventoryFormError extends InventoryFormState {
  final String message;
  const InventoryFormError(this.message);
}

// ==========================================
// ── REPUESTOS STATE & NOTIFIER ─────────────
// ==========================================
class RepuestosState {
  final List<Repuesto> repuestos;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final String search;
  final String ordering;
  final int offset;
  final int limit;
  final bool hasMore;
  final InventoryFormState formState;

  const RepuestosState({
    this.repuestos = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.search = '',
    this.ordering = 'nombre',
    this.offset = 0,
    this.limit = 10,
    this.hasMore = true,
    this.formState = const InventoryFormIdle(),
  });

  RepuestosState copyWith({
    List<Repuesto>? repuestos,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    String? search,
    String? ordering,
    int? offset,
    int? limit,
    bool? hasMore,
    InventoryFormState? formState,
  }) =>
      RepuestosState(
        repuestos: repuestos ?? this.repuestos,
        isLoading: isLoading ?? this.isLoading,
        isMoreLoading: isMoreLoading ?? this.isMoreLoading,
        error: error,
        search: search ?? this.search,
        ordering: ordering ?? this.ordering,
        offset: offset ?? this.offset,
        limit: limit ?? this.limit,
        hasMore: hasMore ?? this.hasMore,
        formState: formState ?? this.formState,
      );
}

class RepuestosNotifier extends StateNotifier<RepuestosState> {
  final InventoryRemoteDatasource _datasource;

  RepuestosNotifier(this._datasource) : super(const RepuestosState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, offset: 0, error: null, hasMore: true);
    try {
      final res = await _datasource.getRepuestos(
        search: state.search,
        ordering: state.ordering,
        limit: state.limit,
        offset: 0,
      );
      state = state.copyWith(
        repuestos: res.results,
        isLoading: false,
        hasMore: res.next != null,
        offset: state.limit,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isMoreLoading || !state.hasMore) return;
    state = state.copyWith(isMoreLoading: true, error: null);
    try {
      final res = await _datasource.getRepuestos(
        search: state.search,
        ordering: state.ordering,
        limit: state.limit,
        offset: state.offset,
      );
      state = state.copyWith(
        repuestos: [...state.repuestos, ...res.results],
        isMoreLoading: false,
        hasMore: res.next != null,
        offset: state.offset + state.limit,
      );
    } catch (e) {
      state = state.copyWith(
        isMoreLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSearch(String q) {
    state = state.copyWith(search: q);
    loadFirstPage();
  }

  void setOrdering(String order) {
    state = state.copyWith(ordering: order);
    loadFirstPage();
  }

  void resetFormState() => state = state.copyWith(formState: const InventoryFormIdle());

  Future<void> create({
    required String nombre,
    String? descripcion,
    required String sku,
    required double costo,
    required double precioVenta,
    required int stock,
    required String estado,
    File? imagen,
  }) async {
    state = state.copyWith(formState: const InventoryFormSaving());
    try {
      final created = await _datasource.createRepuesto(
        nombre: nombre,
        descripcion: descripcion,
        sku: sku,
        costo: costo,
        precioVenta: precioVenta,
        stock: stock,
        estado: estado,
        imagen: imagen,
      );
      state = state.copyWith(
        repuestos: [created, ...state.repuestos],
        formState: const InventoryFormSuccess('Repuesto registrado con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: InventoryFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> update(
    int id, {
    String? nombre,
    String? descripcion,
    String? sku,
    double? costo,
    double? precioVenta,
    int? stock,
    String? estado,
    File? imagen,
  }) async {
    state = state.copyWith(formState: const InventoryFormSaving());
    try {
      final updated = await _datasource.updateRepuesto(
        id,
        nombre: nombre,
        descripcion: descripcion,
        sku: sku,
        costo: costo,
        precioVenta: precioVenta,
        stock: stock,
        estado: estado,
        imagen: imagen,
      );
      state = state.copyWith(
        repuestos: state.repuestos.map((r) => r.idRepuesto == id ? updated : r).toList(),
        formState: const InventoryFormSuccess('Repuesto actualizado con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: InventoryFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await _datasource.deleteRepuesto(id);
      state = state.copyWith(
        repuestos: state.repuestos.where((r) => r.idRepuesto != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final repuestosProvider =
    StateNotifierProvider<RepuestosNotifier, RepuestosState>((ref) {
  return RepuestosNotifier(ref.watch(inventoryDatasourceProvider));
});

// ==========================================
// ── MOVIMIENTOS STATE & NOTIFIER ───────────
// ==========================================
class MovimientosState {
  final List<MovimientoInventario> movimientos;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final String search;
  final String ordering;
  final int offset;
  final int limit;
  final bool hasMore;
  final InventoryFormState formState;

  const MovimientosState({
    this.movimientos = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.search = '',
    this.ordering = '-fecha_movimiento', // Más recientes primero
    this.offset = 0,
    this.limit = 10,
    this.hasMore = true,
    this.formState = const InventoryFormIdle(),
  });

  MovimientosState copyWith({
    List<MovimientoInventario>? movimientos,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    String? search,
    String? ordering,
    int? offset,
    int? limit,
    bool? hasMore,
    InventoryFormState? formState,
  }) =>
      MovimientosState(
        movimientos: movimientos ?? this.movimientos,
        isLoading: isLoading ?? this.isLoading,
        isMoreLoading: isMoreLoading ?? this.isMoreLoading,
        error: error,
        search: search ?? this.search,
        ordering: ordering ?? this.ordering,
        offset: offset ?? this.offset,
        limit: limit ?? this.limit,
        hasMore: hasMore ?? this.hasMore,
        formState: formState ?? this.formState,
      );
}

class MovimientosNotifier extends StateNotifier<MovimientosState> {
  final InventoryRemoteDatasource _datasource;
  final Ref _ref;

  MovimientosNotifier(this._datasource, this._ref) : super(const MovimientosState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, offset: 0, error: null, hasMore: true);
    try {
      final res = await _datasource.getMovimientos(
        search: state.search,
        ordering: state.ordering,
        limit: state.limit,
        offset: 0,
      );
      state = state.copyWith(
        movimientos: res.results,
        isLoading: false,
        hasMore: res.next != null,
        offset: state.limit,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isMoreLoading || !state.hasMore) return;
    state = state.copyWith(isMoreLoading: true, error: null);
    try {
      final res = await _datasource.getMovimientos(
        search: state.search,
        ordering: state.ordering,
        limit: state.limit,
        offset: state.offset,
      );
      state = state.copyWith(
        movimientos: [...state.movimientos, ...res.results],
        isMoreLoading: false,
        hasMore: res.next != null,
        offset: state.offset + state.limit,
      );
    } catch (e) {
      state = state.copyWith(
        isMoreLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSearch(String q) {
    state = state.copyWith(search: q);
    loadFirstPage();
  }

  void setOrdering(String order) {
    state = state.copyWith(ordering: order);
    loadFirstPage();
  }

  void resetFormState() => state = state.copyWith(formState: const InventoryFormIdle());

  Future<void> registerMovement({
    required String tipoMovimiento,
    required int cantidad,
    String? descripcion,
    int? motoId,
    int? repuestoId,
  }) async {
    state = state.copyWith(formState: const InventoryFormSaving());
    try {
      final created = await _datasource.createMovimiento(
        tipoMovimiento: tipoMovimiento,
        cantidad: cantidad,
        descripcion: descripcion,
        motoId: motoId,
        repuestoId: repuestoId,
      );

      // Invalidate catalogs to refresh stocks globally
      _ref.read(motosProvider.notifier).loadFirstPage();
      _ref.read(repuestosProvider.notifier).loadFirstPage();

      state = state.copyWith(
        movimientos: [created, ...state.movimientos],
        formState: const InventoryFormSuccess('Movimiento de inventario registrado con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: InventoryFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }
}

final movimientosProvider =
    StateNotifierProvider<MovimientosNotifier, MovimientosState>((ref) {
  return MovimientosNotifier(ref.watch(inventoryDatasourceProvider), ref);
});
