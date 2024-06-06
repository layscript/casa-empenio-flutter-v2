import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class MotionRepository {
  Future<Either<String, List<MotionEntity>>> getAllMotions();
  Future<Either<String, bool>> createMotion({
    required int idType,
    required int idUser,
    required String obs,
    required double monto,
  });
}
