import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpModulosRepository implements ModulosRepository {
  const HttpModulosRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _dio = dio,
        _sentry = sentry;

  final Dio _dio;
  final SentryClient _sentry;

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
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );

      return const Left('Ocurrió un error');
    }
  }
}
