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
  Future<Either<String, User>> logIn(
      {required String email, required String password}) async {
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

  User userFromMap(Map<String, dynamic> map) {
    print('mapaaaa: $map');
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
}
