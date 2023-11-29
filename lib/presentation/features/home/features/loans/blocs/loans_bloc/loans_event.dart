part of 'loans_bloc.dart';

sealed class LoansEvent extends Equatable {
  const LoansEvent();

  @override
  List<Object> get props => [];
}

class GetLoansInitial extends LoansEvent {}

class GetLoansByDni extends LoansEvent {
  const GetLoansByDni({
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
  });
  final int idPrestamo;
  final String monto;
  final String userId;
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
