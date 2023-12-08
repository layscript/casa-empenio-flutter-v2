import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class CajaRepository {
  Future<Either<String, List<CajaEntity>>> getAllCajas();
  Future<void> getOnlyCaja();
  Future<Either<String, CajaEntity>> getCajaOfTheDay();
  Future<void> deleteCaja();
  Future<bool> openCaja({
    required int userId,
    required double monto,
    required String obs,
  });
  Future<bool> closeCaja({
    required int userId,
    required double monto,
    required String obs,
  });
}
