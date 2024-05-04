part of 'expenses_bloc.dart';

sealed class ExpensesEvent extends Equatable {
  const ExpensesEvent();

  @override
  List<Object> get props => [];
}

class GetCashExpensesStatus extends ExpensesEvent {}

class GetExpenses extends ExpensesEvent {
  const GetExpenses({
    required this.start,
    required this.end,
  });

  final DateTime? start;
  final DateTime? end;
}

class SaveExpense extends ExpensesEvent {
  const SaveExpense({
    required this.obs,
    required this.usuarioId,
    required this.monto,
  });
  final String obs;
  final int usuarioId;
  final String monto;
}
