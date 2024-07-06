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
    required int sucursalId,
  }) async {
    const path = '/finanza/movimiento';
    final payload = {
      'tipoId': idType,
      'suma': false,
      'observaciones': obs,
      'monto': monto,
      'usuarioId': idUser,
      'sucursalId': sucursalId,
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
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, List<MotionEntity>>> getAllMotions({
    required DateTime fechaInicio,
    required DateTime fechafin,
    required int sucursalId,
  }) async {
    final fechaInicioParsed = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
      0,
      0,
      0,
    );

    final fechafinParsed = DateTime(
      fechafin.year,
      fechafin.month,
      fechafin.day,
      23,
      59,
      59,
    );

    final fechaIniP = fechaInicioParsed.toUtc().toIso8601String();
    final fechaFinP = fechafinParsed.toUtc().toIso8601String();

    final path =
        '/finanza/movimiento?limit=1000&offset=0&fechaInicio=$fechaIniP&fechaFin=$fechaFinP&sucursalId=$sucursalId';

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
    } catch (e, stackTrace) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
