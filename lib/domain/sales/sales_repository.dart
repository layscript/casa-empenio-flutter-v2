import 'package:casa_empenio_pe/domain/sales/sales_entity.dart';
import 'package:dartz/dartz.dart';

abstract class SalesRepository {
  Future<Either<String, List<SalesEntity>>> getSalesByRangeDate({
    required DateTime inicio,
    required DateTime fin,
  });

  Future<Either<String, List<SalesEntity>>> getSalesByUserIdRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int userId,
  });

  Future<bool> createSalesProduct(Map<String, dynamic> data);
}
