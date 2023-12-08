import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class ProductRepository {
  Future<Either<String, List<ProductEntity>>> getProducts({
    required int type,
    required String criterio,
  });

  Future<Either<String, List<ProductEntity>>> getProductsLimitFree({
    required String criterio,
  });

  Future<Either<String, List<ProductEntity>>> getProductsLimitSales({
    required String criterio,
  });

  Future<bool> createVehiculo({
    required Map<String, dynamic> payload,
  });
  Future<bool> updateVehiculo({
    required Map<String, dynamic> payload,
  });

  Future<bool> createProduct({
    required Map<String, dynamic> payload,
  });

  Future<bool> updateProduct({
    required Map<String, dynamic> payload,
  });
}
