import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class UserRepository {
  Future<Either<String, User>> logIn({
    required String email,
    required String password,
  });
}
