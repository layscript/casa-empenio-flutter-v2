import 'dart:convert';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpExpensesRepository implements ExpensesRepository {
  const HttpExpensesRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _dio = dio,
        _sentry = sentry;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<Either<String, bool>> createExpense({
    required int id,
    required String obs,
    required double monto,
  }) async {
    const path = '/finanza/movimiento/gasto';
    final payload = {
      'observaciones': obs,
      'monto': monto,
      'usuarioId': id,
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
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, List<ExpensesEntity>>> getAllExpenses() async {
    const path = '/finanza/movimiento/gasto';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'][0];
        return Right(ExpensesEntity.listGetExpensesFromMap(body));
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
  Future<Either<String, bool>> deleteExpense({
    required int id,
  }) async {
    final path = '/finanza/movimiento/$id';

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
      return const Left('Ocurrió un error');
    }
  }
}
