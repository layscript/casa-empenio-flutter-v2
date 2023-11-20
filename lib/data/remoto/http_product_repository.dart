import 'dart:convert';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpProductRepository implements ProductRepository {
  const HttpProductRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<void> createProduct() {
    // TODO: implement createProduct
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProduct() {
    // TODO: implement deleteProduct
    throw UnimplementedError();
  }

  @override
  Future<Either<String, List<Product>>> getProducts({
    required int type,
    required String criterio,
  }) async {
    final query = '?busqueda=$criterio&limit=0&offset=0';
    try {
      /* final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(listGetInterestFromMap(map));
      } */

      Response<String> response;
      switch (type) {
        case 0:
          response = await _dio.get<String>('/almacen/bien$query');
          break;

        case 1:
          response = await _dio.get<String>('/almacen/bien/prestamo$query');

          break;

        default:
          response = await _dio.get<String>('/almacen/bien/sin-prestamo$query');
      }

      print('geeeeettt: 1: ${response.statusCode}');
      print('geeeeettt: 2: ${response.data}');

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(listGetProductsFromMap(map));
      }
    } catch (e) {
      print('geeeeettt: 3: ${e}');
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<void> getProductsLimitFree() {
    // TODO: implement getProductsLimitFree
    throw UnimplementedError();
  }

  @override
  Future<void> getProductsLimitSales() {
    // TODO: implement getProductsLimitSales
    throw UnimplementedError();
  }

  @override
  Future<void> updateProduct() {
    // TODO: implement updateProduct
    throw UnimplementedError();
  }
}

List<Product> listGetProductsFromMap(
  Map<String, dynamic> map,
) {
  final list = map['body'] as List<dynamic>;
  return list.map((e) => getProductFromMap(e as Map<String, dynamic>)).toList();
}

Product getProductFromMap(Map<String, dynamic> map) {
  log('geeeeettt: 5: ${map}');

  return Product(
    id: map['id'] as int?,
    descripcion: map['descripcion'] as String?,
    estado: map['estado'] as String?,
    marca: map['marca'] as String?,
    modelo: map['modelo'] as String?,
    color: map['color'] as String?,
    serie: map['serie'] as String?,
    placa: map['placa'] as String?,
    carroceria: map['carroceria'] as String?,
    motor: map['motor'] as String?,
    anio: map['anio'] as int?,
    valorizacion: map['valorizacion'] as int?,
    observaciones: map['observaciones'] as String?,
    cantidad: map['cantidad'] as int?,
    imagen: map['imagen'] as String?,
    activo: map['activo'] as bool?,
    updatedAt: map['updatedAt'] as String?,
    createdAt: map['createdAt'] as String?,
    prestamo: map['prestamo'] == null ? null : getLoanFromMap(map['prestamo']),
  );
}

Loan? getLoanFromMap(Map<String, dynamic> map) {
  return Loan(
    codigo: map['codigo'] as int?,
    codigoFormateado: map['codigoFormateado'] as String?,
    plazoDias: map['plazoDias'] as int?,
    interes: map['interes'] as int?,
    fechaPago: map['fechaPago'] as String?,
    fechaCierre: map['fechaCierre'] as String?,
    monto: map['monto'] as String?,
    observaciones: map['observaciones'] as String?,
    estado: map['estado'] as String?,
    cerrado: map['cerrado'] as bool?,
    ganancia: map['ganancia'] as String?,
    fecha: map['fecha'] as String?,
    updatedAt: map['updatedAt'] as String?,
    createdAt: map['createdAt'] as String?,
  );
}
