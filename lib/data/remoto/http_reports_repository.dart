import 'dart:convert';
import 'dart:developer';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpReportsRepository implements ReportsRepository {
  const HttpReportsRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _dio = dio,
        _sentry = sentry;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<bool> cancelLoan({
    required int id,
  }) async {
    final path = '/prestamos/prestamos/cancelar/$id';
    try {
      final response = await _dio.put<String>(path);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<Either<String, List<PerdonadosEntity>>> getForgivenessByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
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

    final payload = {
      'fechaInicio': inicioParse.toUtc().toIso8601String(),
      'fechaFin': finParse.toUtc().toIso8601String(),
      'usuarioId': usuarioId,
      'sucursalId': sucursalId,
    };

    const path = '/prestamos/reportes/perdonados';
    try {
      final response = await _dio.post<String>(path, data: payload);

      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;

        final result = PerdonadosEntity.listGetForgivenessFromMap(map['body']);
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
  Future<Either<String, List<LoansEntity>>> getClosedByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
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

    final payload = {
      'fechaInicio': inicioParse.toUtc().toIso8601String(),
      'fechaFin': finParse.toUtc().toIso8601String(),
      'usuarioId': usuarioId,
      'sucursalId': sucursalId,
    };

    const path = '/prestamos/reportes/cerrados';
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final result = LoansEntity.listGetSalesDetailFromMap(map['body']);
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
  Future<Either<String, List<ReportsContractsEntity>>> getIncreasesByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int sucursal,
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

    final path =
        '/prestamos/prestamos/aumentos/${inicioParse.toUtc().toIso8601String()}/${finParse.toUtc().toIso8601String()}/$sucursal';

    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final result =
            ReportsContractsEntity.listGetReportsContractsFromMap(map['body']);
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
  Future<Either<String, List<LoansEntity>>> getLoansByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
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

    final payload = {
      'fechaInicio': inicioParse.toUtc().toIso8601String(),
      'fechaFin': finParse.toUtc().toIso8601String(),
      'usuarioId': usuarioId,
      'sucursalId': sucursalId,
    };

    const path = '/prestamos/reportes';
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final result = LoansEntity.listGetSalesDetailFromMap(map['body']);
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
  Future<Either<String, List<ReportsPaymentEntity>>> getPaymentsByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
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

    final payload = {
      'fechaInicio': inicioParse.toUtc().toIso8601String(),
      'fechaFin': finParse.toUtc().toIso8601String(),
      'usuarioId': usuarioId,
      'sucursalId': sucursalId,
    };

    const path = '/prestamos/reportes/pagos';
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final result =
            ReportsPaymentEntity.listGetReportsPaymentFromMap(map['body']);
        return Right(result);
      }
    } catch (e, stackTrace) {
      print('aslñkdlakñsdadklskladñs: $e');
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> cancelSettledLoan({
    required int id,
  }) async {
    final path = '/prestamos/prestamos/cambiar-estado/$id';
    final payload = {
      'estado': 'CANCELADO',
    };

    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> deleteIncrease({
    required int? id,
    required int? idUser,
  }) async {
    const path = '/prestamos/prestamos/eliminarAumento';

    final payload = {
      'aumentoId': id,
      'usuarioId': idUser,
    };

    try {
      final response = await _dio.post<String>(path, data: payload);

      if (response.statusCode != 201) {
        return false;
      } else {
        return true;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
