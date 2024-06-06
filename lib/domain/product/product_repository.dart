import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class ProductRepository {
  Future<Either<String, List<ProductEntity>>> getProducts({
    required int type,
    String? criterio,
    required int offset,
    String? categoria = '',
  });

  Future<Either<String, List<ProductEntity>>> getProductsLimitFree({
    required String criterio,
  });

  Future<Either<String, List<ProductEntity>>> getProductsLimitSales({
    required String criterio,
  });

  Future<Either<String, bool>> createVehiculo({
    required Map<String, dynamic> payload,
  });
  Future<Either<String, bool>> updateVehiculo({
    required Map<String, dynamic> payload,
  });

  Future<Either<String, bool>> createProduct({
    required Map<String, dynamic> payload,
  });

  Future<Either<String, bool>> updateProduct({
    required Map<String, dynamic> payload,
  });
}
