import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpModulosRepository implements ModulosRepository {
  const HttpModulosRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, List<ModulosEntity>>> getAllModulos({
    String? busqueda = '',
    int? offset = 0,
    int? limit = 10,
  }) async {
    final path =
        '/modulos?limit=$limit&offset=$offset${busqueda!.isEmpty ? '' : '&busqueda=$busqueda'}';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'][0];
        return Right(ModulosEntity.listGetModulosEntityFromMap(body));
      }
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error');
    }
  }
}
