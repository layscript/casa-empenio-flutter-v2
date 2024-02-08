import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpInterestsRepository implements InterestsRepository {
  const HttpInterestsRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
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
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> deleteInterests({
    required int idInterest,
  }) async {
    final path = '/configuraciones/intereses/$idInterest}';
    print('debugg delete 1: ${path}');
    try {
      final response = await _dio.delete<String>(path);
      print('debugg delete 2: ${response.statusCode}');
      print('debugg delete 3: ${response.data}');
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return const Right(true);
      }
    } catch (e) {
      print('debugg delete 4: ${e}');
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
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
      return const Left('Ocurrió un error con el servidor');
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
      return const Left('Ocurrió un error con el servidor');
    }
  }
}
