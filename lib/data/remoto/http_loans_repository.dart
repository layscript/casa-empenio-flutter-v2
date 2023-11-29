import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpLoansRepository implements LoansRepository {
  const HttpLoansRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, int>> getLastCode() async {
    const path = '/prestamos/prestamos/ultimoCodigo';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final code = map['body'] as int;
        return Right(code);
      }
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, LoansEntity>> getLoan({required int id}) async {
    final path = '/prestamos/prestamos/$id';
    try {
      final response = await _dio.get<String>(path);

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(LoansEntity.getLoanFromMap(map['body']));
      }
    } catch (e) {
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<void> getLoans({required String criterio}) {
    // TODO: implement getLoans
    throw UnimplementedError();
  }

  @override
  Future<void> saveLoan({
    required int plazoDias,
    required double interes,
    required DateTime fechaPago,
    required double monto,
    required String observaciones,
    required CustomerEntity cliente,
    required CustomerEntity? aval,
    required List<Map<String, dynamic>> bienes,
    required String usuarioId,
  }) async {
    final endDateTime = DateTime(
      fechaPago.year,
      fechaPago.month,
      fechaPago.day,
      23,
      59,
      59,
    );

    final payload = {
      'plazoDias': plazoDias,
      'interes': interes,
      'fechaPago': endDateTime.toIso8601String(),
      'monto': monto,
      'observaciones': observaciones,
      'cliente': cliente,
      'aval': aval,
      'bienesGarantia': bienes,
      'usuarioId': usuarioId,
    };
  }

  @override
  Future<void> savePayment({
    required int codigo,
    required double monto,
    required String userId,
  }) async {
    const path = '/prestamos/pagos';
    final payload = {
      'monto': monto,
      'prestamoId': codigo,
      'usuarioId': userId,
    };
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<bool> addAmountLoan({
    required int codigo,
    required double monto,
    required String observaciones,
  }) async {
    const path = '/prestamos/prestamos/aumentarMonto';
    final payload = {
      'monto': monto,
      'prestamoId': codigo,
      'observaciones': observaciones,
    };
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        return true;
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  @override
  Future<Uint8List> createInvoicePdf({required String url}) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: downloadFactura));
      final path = url;
      final response = await dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data!);
      } else {
        return Uint8List(0);
      }
    } catch (e) {
      return Uint8List(0);
    }
  }

  @override
  Future<void> createLoanNote({required String id}) async {
    const path = '/facturacion/facturacion/nota/empenio';
    final payload = {'prestamoId': id};
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        /*  return false; */
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        /* return true; */
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      /* return false; */
    }
  }

  @override
  Future<void> createSalesNote({required String id}) async {
    const path = '/facturacion/facturacion/nota/venta';
    final payload = {'ventaId': id};
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        /*  return false; */
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        /* return true; */
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      /* return false; */
    }
  }

  @override
  Future<void> createInvoceLoans({
    required String dni,
    required String fullName,
    required String? direccion,
    required int idPrestamo,
  }) async {
    // TODO: implement createInvoceLoans

    final payload = {
      'dni': dni,
      'nombreCompleto': fullName,
      'direccion': direccion,
      'prestamoId': idPrestamo,
    };

    const path = '/facturacion/facturacion/';

    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        /*  return false; */
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        /* return true; */
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      /* return false; */
    }
  }

  @override
  Future<Either<String, ReportsPaymentEntity>> getPayments(
      {required int id}) async {
    final path = '/prestamos/pagos/$id';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        return Right(ReportsPaymentEntity.getReportsPaymentFromMap(body));
      }
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }
  /*  @override
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
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
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
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
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
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
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
    } catch (e) {
      print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  } */
}
