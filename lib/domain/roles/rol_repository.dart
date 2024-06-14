import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class RolRepository {
  Future<Either<String, List<RoleEntity>>> getRoles({
    String? busqueda,
    int? offset,
  });
  Future<Either<String, bool>> createRol({
    required String nombre,
    required List<int> modulosId,
  });

  Future<Either<String, bool>> updateRol({
    required String id,
    required String nombre,
    required List<int> modulosId,
  });

  Future<Either<String, bool>> deleteRol({
    required String id,
  });
}
