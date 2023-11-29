import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class CustomerRepository {
  Future<Either<String, CustomerEntity>> getCustomerByDni({
    required String dni,
  });
  Future<Either<String, List<CustomerEntity>>> getCustomers();
  Future<Either<String, CustomerSunatEntity>> getCustomerSunatByDni({
    required String dni,
  });
}
