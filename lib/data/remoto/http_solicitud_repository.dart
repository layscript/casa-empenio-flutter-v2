import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpSolicitudRepository implements SolicitudRepository {
  const HttpSolicitudRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, bool>> createSolicitud({
    required String prestamoId,
    required String estado,
    required int usuarioId,
  }) async {
    const path = '/solicitud';
    final payload = {
      'prestamoId': prestamoId,
      'estado': estado,
      'usuarioId': usuarioId,
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
  Future<Either<String, bool>> deleteSolicitud({
    required int solicitudId,
  }) async {
    final path = '/solicitud/$solicitudId';
    try {
      final response = await _dio.delete<String>(path);
      if (response.statusCode != 200) {
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
  Future<Either<String, List<SolicitudEntity>>> getSolicitudes() async {
    const path = '/solicitud?limit=1000&offset=0';
    try {
      final response = await _dio.get<String>(path);
      print('stateee code 1: ${response.statusCode}');
      print('stateee code 2: ${response.data}');
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'][0];
        print('stateee code 3: ${body}');

        return Right(SolicitudEntity.listGetSolicitudFromMap(body));
      }
    } catch (e) {
      print('stateee code 4: ${e}');

      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, bool>> updateSolicitud({
    required int solicitudId,
    required String prestamoId,
    required String estado,
    required int usuarioId,
  }) async {
    final path = '/solicitud/$solicitudId';
    final payload = {
      'prestamoId': prestamoId,
      'estado': estado,
      'usuarioId': usuarioId,
    };

    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode != 200) {
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
  Future<bool> getSolicitudByIdPrestamo({required int idPrestamo}) async {
    final path = '/solicitud/prestamo/$idPrestamo';

    try {
      final response = await _dio.get<String>(path);
      print('asdasdasd 1: ${response.statusCode}');
      print('asdasdasd 2: ${response.data}');

      if (response.statusCode != 200) {
        return false;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        if (body == null) return true;
        final isStatusPending = map['body']?['estado'] == 'PENDIENTE';
        return isStatusPending;
      }
    } catch (e) {
      return false;
    }
  }
}
