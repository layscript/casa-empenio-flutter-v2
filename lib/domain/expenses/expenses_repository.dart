import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class ExpensesRepository {
  Future<Either<String, List<ExpensesEntity>>> getAllExpenses();
  Future<Either<String, bool>> createExpense({
    required int id,
    required String obs,
    required double monto,
  });

  Future<Either<String, bool>> deleteExpense({
    required int id,
  });
}
