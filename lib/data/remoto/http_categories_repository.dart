import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpCategoriesRepository implements CategoriesRepository {
  const HttpCategoriesRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

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
    } catch (e) {
      //print('responseee ee: $e');
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
    } catch (e) {
      //print('responseee ee: $e');
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
    } catch (e) {
      //print('responseee ee: $e');
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
    } catch (e) {
      return false;
    }
  }
}
