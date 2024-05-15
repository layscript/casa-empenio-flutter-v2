import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class ReportsRepository {
  Future<Either<String, List<LoansEntity>>> getLoansByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
    required int sucursalId,
  });
  Future<Either<String, List<LoansEntity>>> getClosedByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
    required int sucursalId,
  });
  Future<Either<String, List<ReportsPaymentEntity>>> getPaymentsByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
    required int sucursalId,
  });

  Future<Either<String, List<PerdonadosEntity>>> getForgivenessByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int usuarioId,
    required int sucursalId,
  });

  Future<Either<String, List<ReportsContractsEntity>>> getIncreasesByRangeDate({
    required DateTime inicio,
    required DateTime fin,
  });
  Future<bool> cancelLoan({required int id});
  Future<bool> cancelSettledLoan({required int id});

  Future<bool> deleteIncrease({
    required int? id,
    required int? idUser,
  });
}
