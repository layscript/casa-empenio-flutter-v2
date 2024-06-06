import 'dart:convert';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpInterestsRepository implements InterestsRepository {
  const HttpInterestsRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _sentry = sentry,
        _dio = dio;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<Either<String, bool>> createInterests({
    required String interest,
  }) async {
    const path = '/configuraciones/intereses';
    final payload = {
      'interes': interest,
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
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> deleteInterests({
    required int idInterest,
  }) async {
    final path = '/configuraciones/intereses/$idInterest}';
    try {
      final response = await _dio.delete<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return const Right(true);
      }
    } catch (e, stackTrace) {
      //print('responseee ee: $e');
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<InterestsEntity>>> getInterest() async {
    const path = '/configuraciones/intereses';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(InterestsEntity.listGetInterestFromMap(map));
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> updateInterests({
    required InterestsEntity interests,
  }) async {
    final path = '/configuraciones/intereses/${interests.id}';
    final payload = {
      'id': interests.id,
      'interes': interests.intereses,
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
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
