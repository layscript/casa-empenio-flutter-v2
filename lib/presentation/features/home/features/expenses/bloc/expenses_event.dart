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
    required this.imagenes,
    this.medioPago,
    this.banco,
  });
  final String obs;
  final int usuarioId;
  final String monto;
  final List<XFile>? imagenes;
  final String? medioPago;
  final String? banco;
}

class DeleteExpense extends ExpensesEvent {
  const DeleteExpense({
    required this.id,
  });

  final int id;
}
