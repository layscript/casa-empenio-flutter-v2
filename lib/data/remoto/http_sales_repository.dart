import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpSalesRepository implements SalesRepository {
  const HttpSalesRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;
  @override
  Future<Either<String, List<SalesEntity>>> getSalesByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int sucursalId,
    required int userId,
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
      'sucursalId': sucursalId,
      'usuarioId': userId,
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
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> createSalesProduct(Map<String, dynamic> payload) async {
    const path = '/almacen/ventas/';
    try {
      final response = await _dio.post<String>(path, data: payload);

      if (response.statusCode != 201) {
        return false;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;

        final parsedMap = {
          'ventaId': map['body']['id'],
        };

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
      return false;
    }
  }

  @override
  Future<int?> registrarVenta(Map<String, dynamic> payload) async {
    try {
      final response =
          await _dio.post<String>('/almacen/ventas/', data: payload);
      if (response.statusCode != 201 && response.statusCode != 200) {
        return null;
      }
      final map = json.decode(response.data!) as Map<String, dynamic>;
      return (map['body']['id'] as num?)?.toInt();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> emitirBoleta(int ventaId) async {
    try {
      final r = await _dio.post<dynamic>(
        '/facturacion/facturacion/venta',
        data: {'ventaId': ventaId},
      );
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> ventasDePrestamo(
      int codigoPrestamo) async {
    try {
      final r = await _dio
          .get<String>('/almacen/ventas/por-prestamo/$codigoPrestamo');
      final map = json.decode(r.data!) as Map<String, dynamic>;
      return (map['body'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String?> guardarContratoVenta(Map<String, dynamic> payload) async {
    try {
      final r = await _dio.post<dynamic>(
        '/expediente/venta-contrato',
        data: payload,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      if (r.statusCode == 201 || r.statusCode == 200) return null;
      return 'No se pudo guardar el contrato';
    } on DioException catch (e) {
      final d = e.response?.data;
      try {
        final m = d is String ? json.decode(d) : d;
        final msg = m is Map ? m['message'] : null;
        if (msg is String) return msg;
        if (msg is List && msg.isNotEmpty) return msg.first.toString();
      } catch (_) {}
      return 'No se pudo guardar el contrato (revise la conexión)';
    } catch (e) {
      return 'No se pudo guardar el contrato';
    }
  }

  @override
  Future<List<Map<String, dynamic>>> contratosDePrestamo(
      int codigoPrestamo) async {
    try {
      final r = await _dio
          .get<String>('/expediente/venta-contrato/prestamo/$codigoPrestamo');
      final map = json.decode(r.data!) as Map<String, dynamic>;
      return (map['body'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String?> cancelarSaldoVenta({
    required int ventaId,
    required int usuarioId,
    required int sucursalId,
    double recargo = 0,
  }) async {
    try {
      final r = await _dio.post<dynamic>(
        '/almacen/ventas/$ventaId/cancelar-saldo',
        data: {
          'usuarioId': usuarioId,
          'sucursalId': sucursalId,
          if (recargo > 0) 'recargo': recargo,
        },
      );
      if (r.statusCode == 201 || r.statusCode == 200) return null;
      return 'No se pudo cancelar el saldo';
    } on DioException catch (e) {
      final d = e.response?.data;
      try {
        final m = d is String ? json.decode(d) : d;
        final msg = m is Map ? m['message'] : null;
        if (msg is String) return msg;
      } catch (_) {}
      return 'No se pudo cancelar el saldo (revise que la caja esté abierta)';
    } catch (e) {
      return 'No se pudo cancelar el saldo';
    }
  }

  @override
  Future<String?> desistirVenta({
    required int ventaId,
    required int usuarioId,
    required int sucursalId,
    double retener = 0,
    String motivo = '',
  }) async {
    try {
      final r = await _dio.post<dynamic>(
        '/almacen/ventas/$ventaId/desistir',
        data: {
          'usuarioId': usuarioId,
          'sucursalId': sucursalId,
          'retener': retener,
          if (motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
        },
      );
      if (r.statusCode == 201 || r.statusCode == 200) return null;
      return 'No se pudo registrar el desistimiento';
    } on DioException catch (e) {
      final d = e.response?.data;
      try {
        final m = d is String ? json.decode(d) : d;
        final msg = m is Map ? m['message'] : null;
        if (msg is String) return msg;
      } catch (_) {}
      return 'No se pudo registrar el desistimiento (revise que la caja esté abierta)';
    } catch (e) {
      return 'No se pudo registrar el desistimiento';
    }
  }

  @override
  Future<Either<String, List<SalesEntity>>> getSalesByUserIdRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int userId,
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
      'usuarioId': userId,
      'sucursalId': sucursalId,
    };

    const path = '/almacen/ventas/usuario';
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
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
