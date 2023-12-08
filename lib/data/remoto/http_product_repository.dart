import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpProductRepository implements ProductRepository {
  const HttpProductRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<bool> createVehiculo({
    required Map<String, dynamic> payload,
  }) async {
    const path = '/almacen/bien/vehiculo';
    try {
      final response = await _dio.post<String>(path, data: payload);
      print('saveeeee 1: ${response.statusCode}');
      print('saveeeee 2: ${response.data}');

      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        if (payload['imagen'] != null && payload['imagen2']) {
          /*  final result = uploadWarrantyImageProductVehiculo(
            path: payload['imagen'],
            idGarantia: data['id'],
          ); */
          final result = uploadWarrantyImageProductVehiculo(
            idGarantia: data['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );
          return result;
        } else {
          return true;
        }
        //return const Right(true);
      }
    } catch (e) {
      print('saveeeee 3: ${e}');

      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  @override
  Future<bool> updateVehiculo({
    required Map<String, dynamic> payload,
  }) async {
    final id = payload['id'];
    final path = '/almacen/bien/vehiculo/$id';
    try {
      final response = await _dio.put<String>(path, data: payload);
      print('saveeeee 1.1: ${response.statusCode}');
      print('saveeeee 2.2: ${response.data}');
      if (response.statusCode == 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        log('saveeeee 55: ${payload}');
        if (payload['imagen'] != null && payload['imagen2'] != null) {
          /*  final result = uploadWarrantyImageProductVehiculo(
            path: payload['imagen'],
            idGarantia: payload['id'],
          ); */
          final result = uploadWarrantyImageProductVehiculo(
            idGarantia: payload['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );
          return result;
        } else {
          return true;
        }
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
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
      return const Left('Ocurrió un error con el servidor');
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
      return const Left('Ocurrió un error con el servidor');
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
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> createProduct({
    required Map<String, dynamic> payload,
  }) async {
    const path = '/almacen/bien';
    try {
      final response = await _dio.post<String>(path, data: payload);
      print('saveeeee 1: ${response.statusCode}');
      print('saveeeee 2: ${response.data}');

      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        print('saveeeee 3: ${map}');
        print('saveeeee 4: ${data}');

        if (payload['imagen'] != null && payload['imagen2'] != null) {
          print('saveeeee 5: ${payload}');
          print('saveeeee 6: ${data}');

          final result = uploadWarrantyImageProductVehiculo(
            idGarantia: data['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );

          print('saveeeee 7: ${result}');

          return result;
        } else {
          return true;
        }
        //return const Right(true);
      }
    } catch (e) {
      print('saveeeee 10: ${e}');

      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  @override
  Future<bool> updateProduct({
    required Map<String, dynamic> payload,
  }) async {
    final id = payload['id'];
    final path = '/almacen/bien/$id';
    try {
      final response = await _dio.put<String>(path, data: payload);
      print('saveeeee 1.1: ${response.statusCode}');
      print('saveeeee 2.2: ${response.data}');
      if (response.statusCode == 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        print('saveeeee 2.3: ${map}');

        final data = map['body'];
        print('saveeeee 2.4: ${data}');

        if (payload['imagen'] != null && payload['imagen2'] != null) {
          print('saveeeee 2.5: ${payload}');

          final result = uploadWarrantyImageProductVehiculo(
            idGarantia: payload['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );

          print('saveeeee 2.6: ${result}');

          return result;
        } else {
          return true;
        }
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  Future<bool> uploadWarrantyImageProductVehiculo({
    required int idGarantia,
    required String imagenUno,
    required String imagenDos,
  }) async {
    if (imagenUno.contains('files/garantias') ||
        imagenDos.contains('files/garantias')) {
      return true;
    }

    print('skadlkjlsakjlsad 1: ${idGarantia}');
    print('skadlkjlsakjlsad 2: ${imagenUno}');
    print('skadlkjlsakjlsad 3: ${imagenDos}');

    final imgUno = File(imagenUno);
    final imgDos = File(imagenDos);
    try {
      final path = '/prestamos/prestamos/imagenGarantia/$idGarantia';

      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          imgUno.path,
          filename: imgUno.path.split('/').last,
        ),
        'imagen2': await MultipartFile.fromFile(
          imgDos.path,
          filename: imgDos.path.split('/').last,
        ),
      });
      final response = await _dio.put(path, data: formData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
