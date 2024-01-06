import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpHistorialRepository implements HistorialRepository {
  const HttpHistorialRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, List<HistorialEntity>?>> getHistorialByUser({
    required int userId,
  }) async {
    final path = '/historial/byUser?limit=10000&userId=$userId';
    try {
      final response = await _dio.get<String>(path);
      print('debuggg 1: ${response.statusCode}');
      print('debuggg 2: ${response.data}');

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        if (response.data == '') {
          return const Right([]);
        } else {
          final map = json.decode(response.data!) as Map<String, dynamic>;
          return Right(HistorialEntity.listGetHistorialFromMap(map));
        }
      }
    } catch (e) {
      print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
