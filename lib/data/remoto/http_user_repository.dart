import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HttpUserRepository implements UserRepository {
  const HttpUserRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<String, User>> logIn({
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
        return Right(userFromMap(data));
      }
    } catch (e) {
      print('messageee 2.6: ${e}');

      return const Left('Ocurrió un error 2');
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
      print('resposopd 1: ${response.statusCode}');
      print('resposopd 2: ${response.data}');

      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return const Right(true);
      }
    } catch (e) {
      print('resposopd 3: ${e}');

      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
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
      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }

  @override
  Future<Either<String, List<User>>> getUsers({
    required int limit,
    required int offset,
  }) async {
    final path = '/usuarios/?limit=$limit&offset=$offset';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        print('debugbeu 1: $map');
        return Right(listGetUsersFromMap(map));
      }
    } catch (e) {
      //print('responseee ee: $e');
      print('debugbeu 2: $e');

      return const Left('Ocurrió un error 2');
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
      print('resposopd 1: ${response.statusCode}');
      print('resposopd 2: ${response.data}');

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return const Right(true);
      }
    } catch (e) {
      print('resposopd 3: ${e}');

      //print('responseee ee: $e');
      return const Left('Ocurrió un error 2');
    }
  }
}

List<User> listGetUsersFromMap(
  Map<String, dynamic> map,
) {
  print('debugbeu 3.1: $map');

  final list = map['body'][0] as List<dynamic>;
  print('debugbeu 3.2: $list');

  return list.map((e) => userFromMap(e as Map<String, dynamic>)).toList();
}

User userFromMap(Map<String, dynamic> map) {
  print('debugbeu 2: $map');

  return User(
    id: map['id'] as int,
    nombre: map['nombre'] as String,
    apellido: map['apellido'] as String,
    userName: map['userName'] as String,
    email: map['email'] as String,
    avatar: map['avatar'] as String?,
    celular: map['celular'] as int,
    role: roleFromMap(map['role']),
  );
}

Role roleFromMap(Map<String, dynamic> map) =>
    Role(id: map['id'] as int, nombre: map['nombre'] as String);
