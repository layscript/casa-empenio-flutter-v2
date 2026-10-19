import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class LoansRepository {
  Future<Either<String, int>> getLastCode();
  Future<Either<String, LoansEntity>> getLoan({
    required int id,
    required int? userId,
  });
  Future<Either<String, List<LoansEntity>>> getLoans({
    required String? criterio,
    required int? userId,
    required int sucursal,
    String? categoria,
    int offset = 0,
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
    required bool renew,
    required int? cajaId,
    required int? sucursalId,
    int? parentLoanId,
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
    required int? cajaId,
    required int? sucursalId,
  });

  Future<bool> updateStatusLoan({
    required int idLoan,
    required String value,
  });
  Future<Either<String, bool>> deleteLoan({
    required int idLoan,
    required String userId,
  });

  Future<bool> anularLoan({
    required int idLoan,
    required String userId,
  });

  Future<Either<String, ReportsPaymentEntity>> getPayments({
    required int id,
  });

  Future<Either<String, bool>> deletePayment({
    required int id,
    required int userId,
  });

  Future<bool> savePayment({
    required int codigo,
    required double monto,
    required String userId,
    required String url,
    required bool? efectivo,
    required int? cajaId,
    bool isLiquidacion,
    String? medioPago,
    String? banco,
  });

  Future<bool> payOffLoan({
    required int id,
    required int idPrestamo,
    required String userId,
  });

  Future<bool> addAmountLoan({
    required int codigo,
    required double monto,
    required String observaciones,
    required String userId,
    required String url,
  });

  Future<Uint8List> createInvoicePdf({required String url});
  Future<void> createSalesNote({required String id});
  Future<void> createLoanNote({required String id});
  Future<bool> createInvoceLoans({
    required String dni,
    required String fullName,
    required String? direccion,
    required int idPrestamo,
    required String userId,
  });

  Future<Either<String, String>> createImagePagos({
    required String path,
  });

  Future<Either<String, String>> createImageAumentos({
    required String path,
  });
}
