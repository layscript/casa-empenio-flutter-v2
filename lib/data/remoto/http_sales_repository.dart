import 'dart:convert';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpSalesRepository implements SalesRepository {
  const HttpSalesRepository({
    required Dio dio,
    required SentryClient sentry,
  })  : _sentry = sentry,
        _dio = dio;

  final Dio _dio;
  final SentryClient _sentry;
  @override
  Future<Either<String, List<SalesEntity>>> getSalesByRangeDate({
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

    const path = '/almacen/ventas/reporte';
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final result = SalesEntity.listGetSalesFromMap(map['body']);

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
  Future<bool> createSalesProduct(Map<String, dynamic> payload) async {
    const path = '/almacen/ventas/';
    try {
      final response = await _dio.post<String>(path, data: payload);
      print('asdasdasdsadasdasa 1: ${response.data}');
      print('asdasdasdsadasdasa 2: ${response.statusCode}');

      if (response.statusCode != 201) {
        return false;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        print('veveveentaaa 1: $map');

        final parsedMap = {
          'ventaId': map['body']['id'],
        };

        print('veveveentaaa 2: $parsedMap');

        // TODOOOO:: Facturación
        final responseFactura = await _dio.post(
          '/facturacion/facturacion/venta',
          data: parsedMap,
        );

        if (responseFactura.statusCode != 201) {
          return false;
        } else {
          return true;
        }
        //return true;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      print('asdasdasdsadasdasa 3: $e');
      return false;
    }
  }
}
