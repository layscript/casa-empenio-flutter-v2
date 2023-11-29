import 'dart:convert';

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
  Future<Either<String, List<ProductEntity>>> getProducts({
    required int type,
    required String criterio,
  }) async {
    final query = '?busqueda=$criterio&limit=0&offset=0';
    try {
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

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(ProductEntity.listGetProductsFromMap(map));
      }
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getProductsLimitFree({
    required String criterio,
  }) async {
    final query = '?busqueda=$criterio&limit=20&offset=0';
    final path = '/almacen/bien/limit/libre$query';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(ProductEntity.listGetProductsFromMap(map));
      }
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getProductsLimitSales({
    required String criterio,
  }) async {
    final query = '?busqueda=$criterio&limit=20&offset=0';
    final path = '/almacen/bien/limit/venta$query';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(ProductEntity.listGetProductsFromMap(map));
      }
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<void> updateProduct() {
    // TODO: implement updateProduct
    throw UnimplementedError();
  }
}
