import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class CajaRepository {
  Future<Either<String, List<CajaEntity>>> getAllCajas();
  Future<void> getOnlyCaja();
  Future<Either<String, CajaEntity?>> getCajaOfTheDay();
  Future<void> deleteCaja();
  Future<Either<String, bool>> openCaja({
    required int userId,
    required double monto,
    required String obs,
  });
  Future<Either<String, bool>> closeCaja({
    required int userId,
    required double monto,
    required String obs,
  });

  Future<Either<String, bool>> aumentarMonto({
    required int userId,
    required double monto,
    required String obs,
  });
}
