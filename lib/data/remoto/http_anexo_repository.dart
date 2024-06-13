import 'dart:convert';
import 'dart:io';

import 'package:casa_empenio_pe/domain/anexo/anexo_entity.dart';
import 'package:casa_empenio_pe/domain/anexo/anexo_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpAnexoRepository implements AnexoRepository {
  const HttpAnexoRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _sentry = sentry,
        _dio = dio;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<Either<String, bool>> createAnexo({
    required String description,
    required List<Map> url,
    required String prestamoId,
  }) async {
    final payload = {
      'descripcion': description,
      //'url': url,
      'url': url.first['url'],
      'prestamoId': prestamoId,
    };

    const path = '/comercial/anexo';
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
  Future<Either<String, bool>> deleteAnexo({
    required String id,
  }) async {
    final path = '/comercial/anexo/$id';
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
  Future<Either<String, List<AnexoEntity>>> getAnexoByPrestamo({
    required String prestamoId,
  }) async {
    final path = '/comercial/anexo/prestamo/$prestamoId';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(AnexoEntity.listGetAnexosFromMap(map['body']));
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
  Future<Either<String, List<AnexoEntity>>> getAnexos({
    required DateTime inicio,
    required DateTime fin,
    required int sucursalId,
  }) async {
    final inicioParse = DateTime(
      inicio.year,
      inicio.month,
      inicio.day,
      0,
      0,
      0,
    );

    final finParse = DateTime(
      fin.year,
      fin.month,
      fin.day,
      23,
      59,
      59,
    );

    final fechaInicio = inicioParse.toUtc().toIso8601String();
    final fechaFin = finParse.toUtc().toIso8601String();

    final path =
        '/comercial/anexo?fechaInicio=$fechaInicio&fechaFin=$fechaFin&sucursalId=$sucursalId';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final result = AnexoEntity.listGetAnexosFromMap(map['body']);
        return Right(result);
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
  Future<Either<String, String>> createImage({
    required String path,
  }) async {
    final img = File(path);
    try {
      const path = '/comercial/anexo/imagenAnexo';
      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          img.path,
          filename: img.path.split('/').last,
        )
      });

      final response = await _dio.post(path, data: formData);

      if (response.statusCode == 201) {
        final body = response.data['body']['url'] as String;
        return Right(body);
      } else {
        return const Left('No se pudo grabar la imagen');
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }
}
