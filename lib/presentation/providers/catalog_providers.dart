// lib/presentation/providers/catalog_providers.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/api/catalog_remote_datasource.dart';
import '../../domain/model/marca.dart';
import '../../domain/model/categoria_moto.dart';
import '../../domain/model/moto.dart';

// ── Estados de Formulario Genéricos ──────────────────────────────
sealed class CatalogFormState { const CatalogFormState(); }
class CatalogFormIdle extends CatalogFormState { const CatalogFormIdle(); }
class CatalogFormSaving extends CatalogFormState { const CatalogFormSaving(); }
class CatalogFormSuccess extends CatalogFormState {
  final String message;
  const CatalogFormSuccess(this.message);
}
class CatalogFormError extends CatalogFormState {
  final String message;
  const CatalogFormError(this.message);
}

// ==========================================
// ── MARCAS STATE & NOTIFIER ────────────────
// ==========================================
class MarcasState {
  final List<Marca> marcas;
  final bool isLoading;
  final String? error;
  final String search;
  final String ordering;
  final CatalogFormState formState;

  const MarcasState({
    this.marcas = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.ordering = 'nombre', // Default ordenar por nombre
    this.formState = const CatalogFormIdle(),
  });

  MarcasState copyWith({
    List<Marca>? marcas,
    bool? isLoading,
    String? error,
    String? search,
    String? ordering,
    CatalogFormState? formState,
  }) =>
      MarcasState(
        marcas: marcas ?? this.marcas,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        search: search ?? this.search,
        ordering: ordering ?? this.ordering,
        formState: formState ?? this.formState,
      );
}

class MarcasNotifier extends StateNotifier<MarcasState> {
  final CatalogRemoteDatasource _datasource;

  MarcasNotifier(this._datasource) : super(const MarcasState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _datasource.getMarcas(
        search: state.search,
        ordering: state.ordering,
      );
      state = state.copyWith(
        marcas: res.results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSearch(String q) {
    state = state.copyWith(search: q);
    load();
  }

  void setOrdering(String order) {
    state = state.copyWith(ordering: order);
    load();
  }

  void resetFormState() => state = state.copyWith(formState: const CatalogFormIdle());

  Future<void> create(String nombre, String? descripcion) async {
    state = state.copyWith(formState: const CatalogFormSaving());
    try {
      final payload = {'nombre': nombre, 'descripcion': descripcion, 'estado': true};
      final created = await _datasource.createMarca(payload);
      state = state.copyWith(
        marcas: [...state.marcas, created],
        formState: const CatalogFormSuccess('Marca creada con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: CatalogFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> update(int id, String nombre, String? descripcion, bool estado) async {
    state = state.copyWith(formState: const CatalogFormSaving());
    try {
      final payload = {'nombre': nombre, 'descripcion': descripcion, 'estado': estado};
      final updated = await _datasource.updateMarca(id, payload);
      state = state.copyWith(
        marcas: state.marcas.map((m) => m.idMarca == id ? updated : m).toList(),
        formState: const CatalogFormSuccess('Marca actualizada con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: CatalogFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await _datasource.deleteMarca(id);
      state = state.copyWith(
        marcas: state.marcas.where((m) => m.idMarca != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final marcasProvider = StateNotifierProvider<MarcasNotifier, MarcasState>((ref) {
  return MarcasNotifier(ref.watch(catalogDatasourceProvider));
});

// ==========================================
// ── CATEGORÍAS STATE & NOTIFIER ───────────
// ==========================================
class CategoriasState {
  final List<CategoriaMoto> categorias;
  final bool isLoading;
  final String? error;
  final String search;
  final String ordering;
  final CatalogFormState formState;

  const CategoriasState({
    this.categorias = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.ordering = 'nombre',
    this.formState = const CatalogFormIdle(),
  });

  CategoriasState copyWith({
    List<CategoriaMoto>? categorias,
    bool? isLoading,
    String? error,
    String? search,
    String? ordering,
    CatalogFormState? formState,
  }) =>
      CategoriasState(
        categorias: categorias ?? this.categorias,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        search: search ?? this.search,
        ordering: ordering ?? this.ordering,
        formState: formState ?? this.formState,
      );
}

class CategoriasNotifier extends StateNotifier<CategoriasState> {
  final CatalogRemoteDatasource _datasource;

  CategoriasNotifier(this._datasource) : super(const CategoriasState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _datasource.getCategorias(
        search: state.search,
        ordering: state.ordering,
      );
      state = state.copyWith(
        categorias: res.results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSearch(String q) {
    state = state.copyWith(search: q);
    load();
  }

  void setOrdering(String order) {
    state = state.copyWith(ordering: order);
    load();
  }

  void resetFormState() => state = state.copyWith(formState: const CatalogFormIdle());

  Future<void> create(String nombre, String? descripcion) async {
    state = state.copyWith(formState: const CatalogFormSaving());
    try {
      final payload = {'nombre': nombre, 'descripcion': descripcion, 'estado': true};
      final created = await _datasource.createCategoria(payload);
      state = state.copyWith(
        categorias: [...state.categorias, created],
        formState: const CatalogFormSuccess('Categoría creada con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: CatalogFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> update(int id, String nombre, String? descripcion, bool estado) async {
    state = state.copyWith(formState: const CatalogFormSaving());
    try {
      final payload = {'nombre': nombre, 'descripcion': descripcion, 'estado': estado};
      final updated = await _datasource.updateCategoria(id, payload);
      state = state.copyWith(
        categorias: state.categorias.map((c) => c.idCategoria == id ? updated : c).toList(),
        formState: const CatalogFormSuccess('Categoría actualizada con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: CatalogFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await _datasource.deleteCategoria(id);
      state = state.copyWith(
        categorias: state.categorias.where((c) => c.idCategoria != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final categoriasProvider =
    StateNotifierProvider<CategoriasNotifier, CategoriasState>((ref) {
  return CategoriasNotifier(ref.watch(catalogDatasourceProvider));
});

// ==========================================
// ── MOTOS STATE & NOTIFIER ────────────────
// ==========================================
class MotosState {
  final List<Moto> motos;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final String search;
  final String ordering;
  final int offset;
  final int limit;
  final bool hasMore;
  final CatalogFormState formState;

  const MotosState({
    this.motos = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.search = '',
    this.ordering = 'modelo',
    this.offset = 0,
    this.limit = 10,
    this.hasMore = true,
    this.formState = const CatalogFormIdle(),
  });

  MotosState copyWith({
    List<Moto>? motos,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    String? search,
    String? ordering,
    int? offset,
    int? limit,
    bool? hasMore,
    CatalogFormState? formState,
  }) =>
      MotosState(
        motos: motos ?? this.motos,
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

class MotosNotifier extends StateNotifier<MotosState> {
  final CatalogRemoteDatasource _datasource;

  MotosNotifier(this._datasource) : super(const MotosState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, offset: 0, error: null, hasMore: true);
    try {
      final res = await _datasource.getMotos(
        search: state.search,
        ordering: state.ordering,
        limit: state.limit,
        offset: 0,
      );
      state = state.copyWith(
        motos: res.results,
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
      final res = await _datasource.getMotos(
        search: state.search,
        ordering: state.ordering,
        limit: state.limit,
        offset: state.offset,
      );
      state = state.copyWith(
        motos: [...state.motos, ...res.results],
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

  void resetFormState() => state = state.copyWith(formState: const CatalogFormIdle());

  Future<void> create({
    required int categoriaId,
    required int marcaId,
    required String modelo,
    required int anio,
    required int cilindraje,
    required String color,
    required double precio,
    required int stock,
    required String estado,
    File? imagen,
  }) async {
    state = state.copyWith(formState: const CatalogFormSaving());
    try {
      final created = await _datasource.createMoto(
        categoriaId: categoriaId,
        marcaId: marcaId,
        modelo: modelo,
        anio: anio,
        cilindraje: cilindraje,
        color: color,
        precio: precio,
        stock: stock,
        estado: estado,
        imagen: imagen,
      );
      state = state.copyWith(
        motos: [created, ...state.motos],
        formState: const CatalogFormSuccess('Motocicleta registrada con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: CatalogFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> update(
    int id, {
    int? categoriaId,
    int? marcaId,
    String? modelo,
    int? anio,
    int? cilindraje,
    String? color,
    double? precio,
    int? stock,
    String? estado,
    File? imagen,
  }) async {
    state = state.copyWith(formState: const CatalogFormSaving());
    try {
      final updated = await _datasource.updateMoto(
        id,
        categoriaId: categoriaId,
        marcaId: marcaId,
        modelo: modelo,
        anio: anio,
        cilindraje: cilindraje,
        color: color,
        precio: precio,
        stock: stock,
        estado: estado,
        imagen: imagen,
      );
      state = state.copyWith(
        motos: state.motos.map((m) => m.idMoto == id ? updated : m).toList(),
        formState: const CatalogFormSuccess('Motocicleta actualizada con éxito'),
      );
    } catch (e) {
      state = state.copyWith(
        formState: CatalogFormError(e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await _datasource.deleteMoto(id);
      state = state.copyWith(
        motos: state.motos.where((m) => m.idMoto != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final motosProvider = StateNotifierProvider<MotosNotifier, MotosState>((ref) {
  return MotosNotifier(ref.watch(catalogDatasourceProvider));
});
