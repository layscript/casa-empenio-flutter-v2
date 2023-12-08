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
  });

  final bool openBox;
  final ExpensesStatus expensesStatus;
  final List<ExpensesEntity>? listExpenses;
  final String? error;

  bool get isExpensesLoading => expensesStatus == ExpensesStatus.loading;
  bool get isExpensesError => expensesStatus == ExpensesStatus.error;
  bool get isExpensesFailure => expensesStatus == ExpensesStatus.failure;
  bool get isExpensesSuccess => expensesStatus == ExpensesStatus.success;

  ExpensesState copyWith({
    bool? openBox,
    ExpensesStatus? expensesStatus,
    List<ExpensesEntity>? listExpenses,
    String? error,
  }) =>
      ExpensesState(
        openBox: openBox ?? this.openBox,
        expensesStatus: expensesStatus ?? this.expensesStatus,
        listExpenses: listExpenses ?? this.listExpenses,
        error: error,
      );

  @override
  List<Object?> get props => [
        openBox,
        expensesStatus,
        listExpenses,
        error,
      ];
}
