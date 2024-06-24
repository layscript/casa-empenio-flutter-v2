import 'dart:convert';
import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpExpensesRepository implements ExpensesRepository {
  const HttpExpensesRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, bool>> createExpense({
    required int id,
    required String obs,
    required double monto,
    required List<Map> url,
  }) async {
    const path = '/finanza/movimiento/gasto';
    final payload = {
      'observaciones': obs,
      'monto': monto,
      'usuarioId': id,
      'imagenes': url,
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
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, List<ExpensesEntity>>> getAllExpenses({
    required DateTime fechaInicio,
    required DateTime fechafin,
    required int sucursalId,
  }) async {
    //const path = '/finanza/movimiento/gasto?limit=1000&offset=0';

    /*  final payload = {
      'fechaInicio': inicioParse.toUtc().toIso8601String(),
      'fechaFin': finParse.toUtc().toIso8601String(),
      'usuarioId': usuarioId,
      'sucursalId': sucursalId,
    }; */

    final fechaInicioParsed = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
      0,
      0,
      0,
    );

    final fechafinParsed = DateTime(
      fechafin.year,
      fechafin.month,
      fechafin.day,
      23,
      59,
      59,
    );

    final fechaIniP = fechaInicioParsed.toUtc().toIso8601String();
    final fechaFinP = fechafinParsed.toUtc().toIso8601String();

    final path =
        '/finanza/movimiento/gasto?limit=1000&offset=0&fechaInicio=$fechaIniP&fechaFin=$fechaFinP&sucursalId=$sucursalId';
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
      return const Left('Ocurrió un error');
    }
  }

  @override
  Future<Either<String, String>> createImage({
    required String path,
  }) async {
    final img = File(path);
    try {
      const path = '/finanza/movimiento/imagenGasto';
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
      return Left(e.toString());
    }
  }

  /*
 @override
  Future<bool> uploadWarrantyImage({
    required String path,
    required int idGarantia,
  }) async {
    if (path.contains('files/garantias')) {
      return true;
    }

    final img = File(path);

    try {
      final path = '/prestamos/prestamos/imagenGarantia/$idGarantia';

      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          img.path,
          filename: img.path.split('/').last,
        )
      });

      final response = await _dio.put(path, data: formData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
     
      return false;
    }
  }
  */
}
