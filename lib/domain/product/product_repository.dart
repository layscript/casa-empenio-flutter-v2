import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class ProductRepository {
  Future<Either<String, List<Product>>> getProducts({
    required int type,
    required String criterio,
  });

  Future<void> getProductsLimitFree();

  Future<void> getProductsLimitSales();

  Future<void> createProduct();

  Future<void> updateProduct();

  Future<void> deleteProduct();
}
