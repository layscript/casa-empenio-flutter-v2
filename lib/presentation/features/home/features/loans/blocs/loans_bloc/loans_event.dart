part of 'loans_bloc.dart';

sealed class LoansEvent extends Equatable {
  const LoansEvent();

  @override
  List<Object> get props => [];
}

class GetLoansInitial extends LoansEvent {}

class GetCashStatus extends LoansEvent {}

class ChangeTypeSearch extends LoansEvent {
  const ChangeTypeSearch(this.value);
  final bool value;
}

class GetLoansSearchByDni extends LoansEvent {
  const GetLoansSearchByDni({
    required this.value,
  });
  final String value;
}

class GetLoansByDni extends LoansEvent {
  const GetLoansByDni({
    required this.value,
  });
  final String value;
}

class GetLoansByText extends LoansEvent {
  const GetLoansByText({
    required this.value,
  });
  final String value;
}

class GetDetailsLoan extends LoansEvent {
  const GetDetailsLoan(this.value);
  final int value;
}

class GetDataSunatByDni extends LoansEvent {
  const GetDataSunatByDni(this.value);
  final String? value;
}

class SavePaymentLoan extends LoansEvent {
  const SavePaymentLoan({
    required this.idPrestamo,
    required this.monto,
    required this.userId,
    required this.photos,
    required this.montoRestante,
    required this.codigo,
    required this.efectivo,
  });
  final int idPrestamo;
  final String monto;
  final String userId;
  final List<XFile>? photos;
  final String montoRestante;
  final int codigo;
  final bool efectivo;
}

class SaveSettlementLoan extends LoansEvent {
  const SaveSettlementLoan({
    required this.idPrestamo,
    required this.monto,
    required this.userId,
    required this.codigo,
    required this.photos,
    required this.efectivo,
  });
  final int idPrestamo;
  final String monto;
  final String userId;
  final int codigo;
  final List<XFile>? photos;
  final bool efectivo;
}

class AddAmountLoan extends LoansEvent {
  const AddAmountLoan({
    required this.idPrestamo,
    required this.monto,
    required this.obs,
    required this.userId,
    required this.photos,
  });
  final int idPrestamo;
  final double monto;
  final String obs;
  final String userId;
  final List<XFile>? photos;
}

class CreateInvoiceLoans extends LoansEvent {
  const CreateInvoiceLoans({
    required this.dni,
    required this.fullName,
    required this.direccion,
    required this.idPrestamo,
    required this.userId,
  });

  final String dni;
  final String fullName;
  final String? direccion;
  final int idPrestamo;
  final String userId;
}

class UpdateAllLoan extends LoansEvent {
  const UpdateAllLoan({
    required this.isRenew,
    required this.isNuevo,
    required this.userId,
    required this.plazoDias,
    required this.interes,
    required this.fechaPago,
    required this.monto,
    required this.observaciones,
    required this.cliente,
    required this.aval,
    required this.bienes,
    required this.codigo,
  });

  final bool? isRenew;
  final bool isNuevo;
  final String userId;
  final int plazoDias;
  final double interes;
  final DateTime fechaPago;
  final double monto;
  final String observaciones;
  final CustomerEntity cliente;
  final CustomerEntity aval;
  final List<Map<String, dynamic>> bienes;
  final int codigo;
}

class DeleteLoanById extends LoansEvent {
  const DeleteLoanById({
    required this.idLoan,
    required this.userId,
  });
  final int idLoan;
  final String userId;
}

class AnularLoanId extends LoansEvent {
  const AnularLoanId({
    required this.idLoan,
    required this.userId,
  });
  final int idLoan;
  final String userId;
}

class DeletePaymentLoanId extends LoansEvent {
  const DeletePaymentLoanId({
    required this.paymentId,
    required this.userId,
  });
  final int paymentId;
  final String userId;
}

class UpdateStatusLoanById extends LoansEvent {
  const UpdateStatusLoanById({
    required this.idLoan,
    required this.value,
  });
  final int idLoan;
  final String value;
}

class CreateSolicitud extends LoansEvent {
  const CreateSolicitud({
    required this.prestamoId,
    required this.estado,
    required this.usuarioId,
  });

  final String prestamoId;
  final String estado;
  final int usuarioId;
}
