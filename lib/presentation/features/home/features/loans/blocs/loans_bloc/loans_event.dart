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
  });
  final int idPrestamo;
  final String monto;
  final String userId;
}

class SaveSettlementLoan extends LoansEvent {
  const SaveSettlementLoan({
    required this.idPrestamo,
    required this.monto,
    required this.userId,
    required this.codigo,
    required this.photos,
  });
  final int idPrestamo;
  final String monto;
  final String userId;
  final int codigo;
  final List<XFile>? photos;
}

class AddAmountLoan extends LoansEvent {
  const AddAmountLoan({
    required this.idPrestamo,
    required this.monto,
    required this.obs,
  });
  final int idPrestamo;
  final double monto;
  final String obs;
}

class CreateInvoiceLoans extends LoansEvent {
  const CreateInvoiceLoans({
    required this.dni,
    required this.fullName,
    required this.direccion,
    required this.idPrestamo,
  });

  final String dni;
  final String fullName;
  final String? direccion;
  final int idPrestamo;
}

class UpdateAllLoan extends LoansEvent {
  const UpdateAllLoan({
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
  const DeleteLoanById(this.idLoan);
  final int idLoan;
}

class UpdateStatusLoanById extends LoansEvent {
  const UpdateStatusLoanById({
    required this.idLoan,
    required this.value,
  });
  final int idLoan;
  final String value;
}
