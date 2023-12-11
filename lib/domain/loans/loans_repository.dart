import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

abstract class LoansRepository {
  Future<Either<String, int>> getLastCode();
  Future<Either<String, LoansEntity>> getLoan({
    required int id,
  });
  Future<Either<String, List<LoansEntity>>> getLoans({
    required String criterio,
  });
  Future<Either<String, ContratoEntity>> saveLoan({
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

  Future<Either<String, bool>> updateLoan({
    required int plazoDias,
    required double interes,
    required DateTime fechaPago,
    required double monto,
    required String observaciones,
    required CustomerEntity cliente,
    required CustomerEntity? aval,
    required List<Map<String, dynamic>> bienes,
    required String usuarioId,
    required int idLoan,
  });

  Future<bool> updateStatusLoan({
    required int idLoan,
    required String value,
  });
  Future<bool> deleteLoan({required int idLoan});

  Future<Either<String, ReportsPaymentEntity>> getPayments({
    required int id,
  });

  Future<bool> savePayment({
    required int codigo,
    required double monto,
    required String userId,
  });

  Future<bool> payOffLoan({
    required int id,
    required int idPrestamo,
    required List<XFile>? photos,
  });

  Future<bool> addAmountLoan({
    required int codigo,
    required double monto,
    required String observaciones,
  });

  Future<Uint8List> createInvoicePdf({required String url});
  Future<void> createSalesNote({required String id});
  Future<void> createLoanNote({required String id});
  Future<bool> createInvoceLoans({
    required String dni,
    required String fullName,
    required String? direccion,
    required int idPrestamo,
  });

  Future<bool> uploadWarrantyImage({
    required String path,
    required int idGarantia,
  });
}
