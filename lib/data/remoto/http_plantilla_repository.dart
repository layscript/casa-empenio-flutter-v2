import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpPlantillaRepository implements PlantillaRepository {
  const HttpPlantillaRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _sentry = sentry,
        _dio = dio;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<Either<String, String>> getPlantilla() async {
    // TODO: Plantilla 1
    const path = '';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        return Right(body);
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
  Future<Either<String, String>> setPlantilla(String url) async {
    // TODO: Plantilla 2
    const path = '';
    final payload = {
      'html': url,
    };
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final data = map['body'];
        return Right(data);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
