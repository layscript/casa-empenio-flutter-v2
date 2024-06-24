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
    } catch (e, stackTrace) {
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
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, List<SolicitudEntity>>> getSolicitudes() async {
    const path = '/solicitud?limit=1000&offset=0';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'][0];

        return Right(SolicitudEntity.listGetSolicitudFromMap(body));
      }
    } catch (e, stackTrace) {
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
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<bool> getSolicitudByIdPrestamo({required int idPrestamo}) async {
    final path = '/solicitud/prestamo/$idPrestamo';

    try {
      final response = await _dio.get<String>(path);

      if (response.statusCode != 200) {
        return false;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        if (body == null) return true;
        final isStatusPending = map['body']?['estado'] == 'PENDIENTE';
        return isStatusPending;
      }
    } catch (e, stackTrace) {
      return false;
    }
  }
}
