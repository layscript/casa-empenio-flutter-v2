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

  Future<void> createProduct();

  Future<void> updateProduct();

  Future<void> deleteProduct();
}
