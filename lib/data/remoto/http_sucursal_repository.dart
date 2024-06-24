import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpSucursalRepository implements SucursalRepository {
  const HttpSucursalRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, SucursalEntity>> createSucursal({
    required String nombre,
    required String direccion,
  }) async {
    const path = '/sucursal';
    final payload = {
      'nombre': nombre,
      'direccion': direccion,
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
        return Right(SucursalEntity.sucursalFromMap(data));
      }
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<SucursalEntity>>> getSucursales() async {
    const path = '/sucursal';
    try {
      final response = await _dio.get<String>(path);

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(SucursalEntity.listGetSucursalesFromMap(map));
      }
    } catch (e, stackTrace) {
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
