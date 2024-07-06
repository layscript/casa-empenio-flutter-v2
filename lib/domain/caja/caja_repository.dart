import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class CajaRepository {
  Future<Either<String, List<CajaEntity>>> getAllCajas();
  Future<void> getOnlyCaja();
  Future<Either<String, CajaEntity?>> getCajaOfTheDay({
    required int sucursalId,
  });
  Future<void> deleteCaja();
  Future<Either<String, bool>> openCaja({
    required int userId,
    required double monto,
    required String obs,
    required int sucursalId,
  });
  Future<Either<String, bool>> closeCaja({
    required int userId,
    required double monto,
    required String obs,
    required int sucursalId,
  });

  Future<Either<String, bool>> aumentarMonto({
    required int userId,
    required double monto,
    required String obs,
    required int sucursalId,
  });
}
