import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpMotionRepository implements MotionRepository {
  const HttpMotionRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, bool>> createMotion({
    required int idType,
    required int idUser,
    required String obs,
    required double monto,
  }) async {
    const path = '/finanza/movimiento';
    final payload = {
      'tipoId': idType,
      'suma': false,
      'observaciones': obs,
      'monto': monto,
      'usuarioId': idUser,
    };

    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        return const Right(true);
      }
    } catch (e) {
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, List<MotionEntity>>> getAllMotions() async {
    const path = '/finanza/movimiento';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'][0];
        return Right(MotionEntity.listGetMotionFromMap(body));
      }
    } catch (e) {
      print('errpororor 33: $e');
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
