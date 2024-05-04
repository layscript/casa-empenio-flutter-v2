import 'dart:convert';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpCustomerRepository implements CustomerRepository {
  const HttpCustomerRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _sentry = sentry,
        _dio = dio;

  final Dio _dio;
  final SentryClient _sentry;

  @override
  Future<Either<String, CustomerEntity>> getCustomerByDni({
    required String dni,
    required int? userId,
  }) async {
    final path = '/clientes/clientes/dni/$dni';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'] != null;

        if (!body) return const Left('El cliente no existe');
        if (userId != null) {
          await createHistory(
            accion: 'BUSQUEDA',
            detalle: 'busqueda en prestamos con el dni: $dni',
            usuarioId: userId,
          );
        }

        return Right(CustomerEntity.getCustomerFromMap(map['body']));
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
  Future<Either<String, List<CustomerEntity>>> getCustomers() async {
    const path = '/clientes/clientes?limit=1000&offset=0';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'] != null;

        if (!body) return const Left('El cliente no existe');
        return Right(CustomerEntity.listGetCustomerFromMap(map['body']));
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
  Future<Either<String, CustomerSunatEntity>> getCustomerSunatByDni({
    required String dni,
  }) async {
    final path = '/facturacion/facturacion/dni/$dni';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'] != null;
        if (!body) return const Left('El cliente no existe');
        final data = map['body']['data'];
        return Right(CustomerSunatEntity.getCustomerSunatFromMap(data));
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
  Future<bool> createHistory({
    required String accion,
    required String detalle,
    required int usuarioId,
  }) async {
    const path = '/historial';
    final payload = {
      'accion': accion,
      'detalle': detalle,
      'usuarioId': usuarioId,
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
