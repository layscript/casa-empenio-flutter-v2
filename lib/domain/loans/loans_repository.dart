import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class LoansRepository {
  Future<Either<String, int>> getLastCode();
  Future<Either<String, LoansEntity>> getLoan({required int id});
  Future<void> getLoans({required String criterio});
  Future<void> saveLoan({
    required int plazoDias,
    required double interes,
    required DateTime fechaPago,
    required double monto,
    required String observaciones,
    required CustomerEntity cliente,
    required CustomerEntity? aval,
    required List<Map<String, dynamic>> bienes,
    required String usuarioId,
  });

  Future<Either<String, ReportsPaymentEntity>> getPayments({required int id});

  Future<void> savePayment({
    required int codigo,
    required double monto,
    required String userId,
  });

  Future<bool> addAmountLoan({
    required int codigo,
    required double monto,
    required String observaciones,
  });

  Future<Uint8List> createInvoicePdf({required String url});
  Future<void> createSalesNote({required String id});
  Future<void> createLoanNote({required String id});
  Future<void> createInvoceLoans({
    required String dni,
    required String fullName,
    required String? direccion,
    required int idPrestamo,
  });
}
