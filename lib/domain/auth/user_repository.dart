import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class UserRepository {
  Future<Either<String, UserEntity>> logIn({
    required String email,
    required String password,
  });

  Future<Either<String, List<UserEntity>>> getUsers({
    required int limit,
    required int offset,
  });
  Future<Either<String, bool>> createUser({
    required int id,
    required String nombre,
    required String apellido,
    required String userName,
    required String email,
    required int celular,
    required int rolId,
    required String password,
    required int sucursalId,
  });
  Future<Either<String, bool>> updateUser({
    required int id,
    required String nombre,
    required String apellido,
    required String userName,
    required String email,
    required int celular,
    required int rolId,
    required String? password,
    required int sucursalId,
  });
  Future<Either<String, bool>> deleteUser({
    required int idUser,
  });
}
