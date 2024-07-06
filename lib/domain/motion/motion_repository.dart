import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class MotionRepository {
  Future<Either<String, List<MotionEntity>>> getAllMotions({
    required DateTime fechaInicio,
    required DateTime fechafin,
    required int sucursalId,
  });
  Future<Either<String, bool>> createMotion({
    required int idType,
    required int idUser,
    required String obs,
    required double monto,
    required int sucursalId,
  });
}
