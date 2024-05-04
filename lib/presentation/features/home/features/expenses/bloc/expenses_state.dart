part of 'expenses_bloc.dart';

enum ExpensesStatus {
  initial,
  loading,
  error,
  loaded,
  success,
  failure,
}

class ExpensesState extends Equatable {
  const ExpensesState({
    this.openBox = false,
    this.expensesStatus = ExpensesStatus.initial,
    this.listExpenses,
    this.error,
    required this.endExpenses,
    required this.startExpenses,
    this.totalGastos,
  });

  final bool? openBox;
  final ExpensesStatus expensesStatus;
  final List<ExpensesEntity>? listExpenses;
  final String? error;

  final DateTime startExpenses;
  final DateTime endExpenses;
  final double? totalGastos;

  bool get isExpensesLoading => expensesStatus == ExpensesStatus.loading;
  bool get isExpensesError => expensesStatus == ExpensesStatus.error;
  bool get isExpensesFailure => expensesStatus == ExpensesStatus.failure;
  bool get isExpensesSuccess => expensesStatus == ExpensesStatus.success;

  ExpensesState copyWith({
    bool? openBox,
    ExpensesStatus? expensesStatus,
    List<ExpensesEntity>? listExpenses,
    String? error,
    DateTime? startExpenses,
    DateTime? endExpenses,
    double? totalGastos,
  }) =>
      ExpensesState(
        openBox: openBox,
        expensesStatus: expensesStatus ?? this.expensesStatus,
        listExpenses: listExpenses ?? this.listExpenses,
        error: error,
        startExpenses: startExpenses ?? this.startExpenses,
        endExpenses: endExpenses ?? this.endExpenses,
        totalGastos: totalGastos ?? this.totalGastos,
      );

  @override
  List<Object?> get props => [
        openBox,
        expensesStatus,
        listExpenses,
        error,
        startExpenses,
        endExpenses,
        totalGastos,
      ];
}
