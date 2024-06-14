import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpRolRepository implements RolRepository {
  const HttpRolRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _dio = dio,
        _sentry = sentry;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<Either<String, bool>> createRol({
    required String nombre,
    required List<int> modulosId,
  }) async {
    final payload = {
      'modulosId': modulosId,
      'nombre': nombre,
    };

    const path = '/auth/roles';
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
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> deleteRol({
    required String id,
  }) async {
    final path = '/auth/roles/$id';
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
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<RoleEntity>>> getRoles({
    String? busqueda = '',
    int? offset = 0,
  }) async {
    final path =
        '/auth/roles?limit=10&offset=$offset${busqueda!.isEmpty ? '' : '&busqueda=$busqueda'}';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'][0];
        return Right(RoleEntity.listGetRolesFromMap(body));
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );

      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, bool>> updateRol({
    required String id,
    required String nombre,
    required List<int> modulosId,
  }) async {
    final path = '/auth/roles/$id';
    final payload = {
      'modulosId': modulosId,
      'nombre': nombre,
    };
    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return const Right(false);
      } else {
        return const Right(true);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Right(false);
    }
  }
}
