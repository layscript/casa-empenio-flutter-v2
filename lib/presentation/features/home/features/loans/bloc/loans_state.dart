part of 'loans_bloc.dart';

sealed class LoansState extends Equatable {
  const LoansState();

  @override
  List<Object> get props => [];
}

final class LoansInitial extends LoansState {}

final class LoansLoading extends LoansState {}

final class LoansLoaded extends LoansState {
  const LoansLoaded(this.listLoan);
  final List<Loan> listLoan;
}

final class LoansError extends LoansState {
  const LoansError(this.message);
  final String message;
}
