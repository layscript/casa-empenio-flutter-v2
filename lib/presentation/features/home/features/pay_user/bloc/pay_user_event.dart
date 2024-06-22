part of 'pay_user_bloc.dart';

sealed class PayUserEvent extends Equatable {
  const PayUserEvent();

  @override
  List<Object> get props => [];
}

class GetCashPayExpensesStatus extends PayUserEvent {}

class GetPayExpenses extends PayUserEvent {
  const GetPayExpenses({
    required this.start,
    required this.end,
  });

  final DateTime? start;
  final DateTime? end;
}

class SavePayExpense extends PayUserEvent {
  const SavePayExpense({
    required this.obs,
    required this.usuarioId,
    required this.typeId,
    required this.monto,
  });
  final String obs;
  final int usuarioId;
  final int typeId;
  final String monto;
}
