import 'dart:convert';
import 'dart:io';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpCustomerRepository implements CustomerRepository {
  const HttpCustomerRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, CustomerEntity>> getCustomerByDni({
    required String dni,
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

        if (!body) return const Left('El cliente no existe 1');
        return Right(CustomerEntity.getCustomerFromMap(map['body']));
      }
    } catch (e) {
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

        if (!body) return const Left('El cliente no existe 2');
        return Right(CustomerEntity.listGetCustomerFromMap(map['body']));
      }
    } catch (e) {
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
        print('djdjdjdjd 1');
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        print('djdjdjdjd 1.1 : ${message}');

        return Left(message);
      } else {
        print('djdjdjdjd 2');

        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'] != null;

        if (!body) return const Left('El cliente no existe 3');
        final data = map['body']['data'];
        return Right(CustomerSunatEntity.getCustomerSunatFromMap(data));
      }
    } catch (e) {
      print('djdjdjdjd 3');

      return const Left('Ocurrió un error');
    }
  }
}
