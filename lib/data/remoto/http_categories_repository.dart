import 'dart:convert';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpCategoriesRepository implements CategoriesRepository {
  const HttpCategoriesRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _dio = dio,
        _sentry = sentry;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<bool> createCategory({
    required String value,
  }) async {
    const path = '/almacen/producto/categoria';
    final payload = {
      'descripcion': value,
    };
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return true;
      }
    } catch (e, stackTrace) {
      //print('responseee ee: $e');
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> deleteCategory({
    required int idCategory,
  }) async {
    final path = '/almacen/producto/categoria/$idCategory';
    try {
      final response = await _dio.delete<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return true;
      }
    } catch (e, stackTrace) {
      //print('responseee ee: $e')
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<Either<String, List<CategoriesEntity>>> getCategories() async {
    const path = '/almacen/producto/categoria';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(CategoriesEntity.listGetCategoriesFromMap(map));
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
  Future<bool> updateCategory({
    required String value,
    required String idCategory,
  }) async {
    final path = '/almacen/producto/categoria/$idCategory';
    final payload = {
      'descripcion': value,
    };
    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
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
