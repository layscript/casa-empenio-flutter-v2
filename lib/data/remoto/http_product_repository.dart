import 'dart:convert';
import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpProductRepository implements ProductRepository {
  const HttpProductRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _sentry = sentry,
        _dio = dio;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<Either<String, bool>> createVehiculo({
    required Map<String, dynamic> payload,
  }) async {
    const path = '/almacen/bien/vehiculo';
    try {
      final response = await _dio.post<String>(path, data: payload);

      if (response.statusCode == 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        if (payload['imagen'] != null || payload['imagen'] != '') {
          await uploadWarrantyImageProductVehiculo(
            idGarantia: data['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );
        }
        return const Right(true);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, bool>> updateVehiculo({
    required Map<String, dynamic> payload,
  }) async {
    final id = payload['id'];
    final path = '/almacen/bien/vehiculo/$id';
    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode == 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        if (payload['imagen'] != null || payload['imagen'] != '') {
          await uploadWarrantyImageProductVehiculo(
            idGarantia: payload['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );
        }
        return const Right(true);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurró un error');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getProducts({
    required int type,
    String? criterio = '',
    int offset = 0,
    String? categoria = '',
  }) async {
    final query = '?busqueda=$criterio&limit=10&offset=$offset';
    try {
      Response<String> response;
      switch (type) {
        case 0:
          response = await _dio.get<String>(
            '/almacen/bien$query&categoria=$categoria',
          );
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
    } catch (e, stackTrace) {
      //print('responseee ee: $e');
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getProductsLimitFree({
    required String criterio,
  }) async {
    final query = '?busqueda=$criterio&limit=1000&offset=0';
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
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getProductsLimitSales({
    required String criterio,
  }) async {
    final query = '?busqueda=$criterio&limit=1000&offset=0';
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
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> createProduct({
    required Map<String, dynamic> payload,
  }) async {
    const path = '/almacen/bien';
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        if (payload['imagen'] != null || payload['imagen'] != '') {
          await uploadWarrantyImageProductVehiculo(
            idGarantia: data['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );
        }
        return const Right(true);
        //return const Right(true);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, bool>> updateProduct({
    required Map<String, dynamic> payload,
  }) async {
    final id = payload['id'];
    final path = '/almacen/bien/$id';
    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode == 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        if (payload['imagen'] != null || payload['imagen'] != '') {
          await uploadWarrantyImageProductVehiculo(
            idGarantia: payload['id'],
            imagenUno: payload['imagen'],
            imagenDos: payload['imagen2'],
          );
        }
        return const Right(true);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error');
    }
  }

  Future<bool> uploadWarrantyImageProductVehiculo({
    required int idGarantia,
    required String? imagenUno,
    required String? imagenDos,
  }) async {
    try {
      FormData formData = FormData();

      if (imagenUno != null && !imagenUno.contains('files/')) {
        final img = File(imagenUno);
        formData.files.add(MapEntry(
            'imagen',
            await MultipartFile.fromFile(
              img.path,
              filename: img.path.split('/').last,
            )));
      }

      if (imagenDos != null && !imagenDos.contains('files/')) {
        final img2 = File(imagenDos);
        formData.files.add(MapEntry(
            'imagen2',
            await MultipartFile.fromFile(
              img2.path,
              filename: img2.path.split('/').last,
            )));
      }

      if (formData.files.isNotEmpty) {
        final path = '/prestamos/prestamos/imagenGarantia/$idGarantia';
        final response = await _dio.put(path, data: formData);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
