import 'package:casa_empenio_pe/domain/sales/sales_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ProformaRepository {
  Future<Either<String, List<SalesEntity>>> getProformasByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int sucursalId,
    required int userId,
  });

  Future<Either<String, List<SalesEntity>>> getProformasByUserIdRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int userId,
    required int sucursalId,
  });

  Future<bool> createProformasProduct(Map<String, dynamic> data);
}
