import 'dart:convert';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpReportsRepository implements ReportsRepository {
  const HttpReportsRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

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
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<String, List<LoansEntity>>> getClosedByRangeDate({
    required DateTime inicio,
    required DateTime fin,
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
    } catch (e) {
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, List<ReportsContractsEntity>>> getIncreasesByRangeDate({
    required DateTime inicio,
    required DateTime fin,
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
        '/prestamos/prestamos/aumentos/${inicioParse.toUtc().toIso8601String()}/${finParse.toUtc().toIso8601String()}';
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
    } catch (e) {
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, List<LoansEntity>>> getLoansByRangeDate({
    required DateTime inicio,
    required DateTime fin,
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
    } catch (e) {
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, List<ReportsPaymentEntity>>> getPaymentsByRangeDate({
    required DateTime inicio,
    required DateTime fin,
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
    } catch (e) {
      return const Left('Ocurrió un error 2');
    }
  }
}
