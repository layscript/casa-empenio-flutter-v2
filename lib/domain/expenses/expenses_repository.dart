import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class ExpensesRepository {
  Future<Either<String, List<ExpensesEntity>>> getAllExpenses({
    required DateTime fechaInicio,
    required DateTime fechafin,
    required int sucursalId,
  });
  Future<Either<String, bool>> createExpense({
    required int id,
    required String obs,
    required double monto,
    required List<Map> url,
    required int sucursalId,
    String? medioPago,
    String? banco,
  });

  Future<Either<String, bool>> deleteExpense({
    required int id,
  });

  Future<Either<String, String>> createImage({
    required String path,
  });
}
