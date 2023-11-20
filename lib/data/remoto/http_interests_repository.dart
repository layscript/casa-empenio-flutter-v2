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
  Future<Either<String, List<Interests>>> getInterest() async {
    const path = '/configuraciones/intereses';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(listGetInterestFromMap(map));
      }
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, bool>> updateInterests({
    required Interests interests,
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
  }
}

List<Interests> listGetInterestFromMap(
  Map<String, dynamic> map,
) {
  final list = map['body'] as List<dynamic>;
  return list
      .map((e) => getInterestFromMap(e as Map<String, dynamic>))
      .toList();
}

Interests getInterestFromMap(Map<String, dynamic> map) {
  return Interests(
    id: map['id'] as int,
    intereses: map['interes'] as String,
  );
}
