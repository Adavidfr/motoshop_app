// lib/data/remote/api/carrito_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/model/carrito.dart';
import 'dio_client.dart';

abstract class CarritoRemoteDatasource {
  Future<CarritoModel>  getCarritoActivo();
  Future<CarritoModel>  crearCarrito();
  Future<CarritoModel>  addItem({
    required int carritoId,
    int?     idMoto,
    int?     idRepuesto,
    required int cantidad,
    required double precioUnitario,
  });
  Future<CarritoModel>  removeItem({required int carritoId, required int itemId});
  Future<CarritoModel>  vaciarCarrito(int carritoId);
}

class CarritoRemoteDatasourceImpl implements CarritoRemoteDatasource {
  final Dio _dio;
  CarritoRemoteDatasourceImpl(this._dio);

  @override
  Future<CarritoModel> getCarritoActivo() async {
    final res = await _dio.get('/carritos/activo/');
    return CarritoModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<CarritoModel> crearCarrito() async {
    final res = await _dio.post('/carritos/', data: {'estado': 'activo'});
    return CarritoModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<CarritoModel> addItem({
    required int carritoId,
    int?     idMoto,
    int?     idRepuesto,
    required int cantidad,
    required double precioUnitario,
  }) async {
    final body = <String, dynamic>{
      'cantidad':         cantidad,
      'precio_unitario':  precioUnitario.toStringAsFixed(2),
    };
    if (idMoto     != null) body['id_moto']     = idMoto;
    if (idRepuesto != null) body['id_repuesto'] = idRepuesto;

    final res = await _dio.post(
      '/carritos/$carritoId/add-item/',
      data: body,
    );
    return CarritoModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<CarritoModel> removeItem({
    required int carritoId,
    required int itemId,
  }) async {
    final res = await _dio.delete('/carritos/$carritoId/remove-item/$itemId/');
    return CarritoModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<CarritoModel> vaciarCarrito(int carritoId) async {
    final res = await _dio.post('/carritos/$carritoId/vaciar/');
    return CarritoModel.fromJson(res.data as Map<String, dynamic>);
  }
}

final carritoDatasourceProvider = Provider<CarritoRemoteDatasource>((ref) {
  return CarritoRemoteDatasourceImpl(ref.watch(dioProvider));
});
