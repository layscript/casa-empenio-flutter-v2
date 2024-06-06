import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class CategoriesRepository {
  Future<Either<String, List<CategoriesEntity>>> getCategories();
  Future<bool> createCategory({required String value});
  Future<bool> updateCategory({
    required String value,
    required String idCategory,
  });
  Future<bool> deleteCategory({required int idCategory});
}
