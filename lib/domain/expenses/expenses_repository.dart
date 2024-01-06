import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class ExpensesRepository {
  Future<Either<String, List<ExpensesEntity>>> getAllExpenses();
  Future<Either<String, bool>> createExpense({
    required int id,
    required String obs,
    required double monto,
  });
}
