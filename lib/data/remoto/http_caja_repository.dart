import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpCajaRepository implements CajaRepository {
  const HttpCajaRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, bool>> closeCaja({
    required int userId,
    required double monto,
    required String obs,
  }) async {
    const path = '/finanza/caja/cerrar';
    final payload = {
      'usuarioId': userId,
      'monto': monto,
      'observaciones': obs,
    };

    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return const Right(true);
      }
    } catch (e) {
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<void> deleteCaja() {
    // TODO: implement deleteCaja
    throw UnimplementedError();
  }

  @override
  Future<Either<String, List<CajaEntity>>> getAllCajas() async {
    const path = '/finanza/caja';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        print('errpororor 1: $map');
        final body = map['body'][0];
        print('errpororor 2: $body');
        return Right(CajaEntity.listGetCajaFromMap(body));
      }
    } catch (e) {
      print('errpororor 33: $e');
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, CajaEntity?>> getCajaOfTheDay() async {
    const path = '/finanza/caja/actual';
    try {
      final response = await _dio.get<String>(path);
      print('xxxxdebuggg 1: ${response.statusCode}');
      print('xxxxdebuggg 2: ${response.data}');

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        if (body != null) {
          return Right(CajaEntity.getCajaFromMap(body));
        } else {
          return const Right(null);
        }
      }
    } catch (e) {
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<void> getOnlyCaja() {
    // TODO: implement getOnlyCaja
    throw UnimplementedError();
  }

  @override
  Future<Either<String, bool>> openCaja({
    required int userId,
    required double monto,
    required String obs,
  }) async {
    const path = '/finanza/caja/abrir';
    final payload = {
      'usuarioId': userId,
      'monto': monto,
      'observaciones': obs,
    };

    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return const Right(true);
      }
    } catch (e) {
      return const Left('Ocurrió un error');
    }
  }
}
