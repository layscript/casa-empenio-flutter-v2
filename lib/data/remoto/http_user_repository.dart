import 'dart:convert';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpUserRepository implements UserRepository {
  const HttpUserRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, UserEntity>> logIn({
    required String email,
    required String password,
  }) async {
    const path = '/usuarios/login';
    final payload = {
      'userName': email,
      'password': password,
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
        return Right(UserEntity.userFromMap(data));
      }
    } catch (e) {
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> createUser({
    required int id,
    required String nombre,
    required String apellido,
    required String userName,
    required String email,
    required int celular,
    required int rolId,
    required String password,
  }) async {
    const path = '/usuarios';
    final payload = {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'userName': userName,
      'email': email,
      'celular': celular,
      'rolId': rolId,
      'password': password,
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
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> deleteUser({required int idUser}) async {
    final path = '/usuarios/$idUser}';
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
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<UserEntity>>> getUsers({
    required int limit,
    required int offset,
  }) async {
    final path = '/usuarios/?limit=$limit&offset=$offset';
    try {
      final response = await _dio.get<String>(path);
      log('debugggg 1: ${response.statusCode}');
      log('debugggg 2: ${response.data}');

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(UserEntity.listGetUsersFromMap(map));
      }
    } catch (e) {
      log('debugggg 3: ${e}');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> updateUser({
    required int id,
    required String nombre,
    required String apellido,
    required String userName,
    required String email,
    required int celular,
    required int rolId,
    required String? password,
  }) async {
    final path = '/usuarios/$id';
    final payload = {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'userName': userName,
      'email': email,
      'celular': celular,
      'rolId': rolId,
    };

    if (password != '') {
      payload['password'] = password!;
    }

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
