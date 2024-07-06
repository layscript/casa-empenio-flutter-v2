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
    required int sucursalId,
  }) async {
    const path = '/finanza/caja/cerrar';
    final payload = {
      'usuarioId': userId,
      'monto': monto,
      'observaciones': obs,
      'sucursalId': sucursalId,
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
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<void> deleteCaja() {
    // TODO: implement deleteCaja
    throw UnimplementedError();
  }

  @override
  Future<Either<String, List<CajaEntity>>> getAllCajas({
    required int sucursalId,
  }) async {
    final path = '/finanza/caja?sucursalId=$sucursalId';

    print('bkc');
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'][0] as List<dynamic>?;
        if (body == null) {
          return const Left('No hay cajas');
        } else {
          return Right(CajaEntity.listGetCajaFromMap(body, false));
        }
      }
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, CajaEntity?>> getCajaOfTheDay({
    required int sucursalId,
  }) async {
    final path = '/finanza/caja/actual/$sucursalId';

    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        if (body != null) {
          return Right(CajaEntity.getCajaFromMap(body, false));
        } else {
          return const Right(null);
        }
      }
    } catch (e, stackTrace) {
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
    required int sucursalId,
  }) async {
    const path = '/finanza/caja/abrir';
    final payload = {
      'usuarioId': userId,
      'monto': monto,
      'observaciones': obs,
      'sucursalId': sucursalId,
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
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, bool>> aumentarMonto({
    required int userId,
    required double monto,
    required String obs,
    required int sucursalId,
  }) async {
    const path = '/finanza/caja/aumentarMonto';
    final payload = {
      'usuarioId': userId,
      'monto': monto,
      'observaciones': obs,
      'sucursalId': sucursalId,
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
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error');
    }
  }
}
