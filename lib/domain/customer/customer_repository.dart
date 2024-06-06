import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class CustomerRepository {
  Future<Either<String, CustomerEntity>> getCustomerByDni({
    required String dni,
    required int? userId,
    required int sucursal,
  });
  Future<Either<String, List<CustomerEntity>>> getCustomers();
  Future<Either<String, CustomerSunatEntity>> getCustomerSunatByDni({
    required String dni,
  });
  Future<bool> createHistory({
    required String accion,
    required String detalle,
    required int usuarioId,
  });
}
