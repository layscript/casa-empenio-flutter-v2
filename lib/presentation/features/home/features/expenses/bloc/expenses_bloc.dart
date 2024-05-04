import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'expenses_event.dart';
part 'expenses_state.dart';

final _initialState = ExpensesState(
  startExpenses: DateTime.now().subtract(const Duration(days: 1)),
  endExpenses: DateTime.now(),
);

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  ExpensesBloc({
    required ExpensesRepository expensesRepository,
    required CajaRepository cajaRepository,
  })  : _expensesRepository = expensesRepository,
        _cajaRepository = cajaRepository,
        super(_initialState) {
    on<GetExpenses>(_onGetExpenses);
    on<SaveExpense>(_onSaveExpense);
    on<GetCashExpensesStatus>(_onGetCashExpensesStatus);
  }

  final ExpensesRepository _expensesRepository;
  final CajaRepository _cajaRepository;

  Future<void> _onGetExpenses(
    GetExpenses event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(state.copyWith(expensesStatus: ExpensesStatus.loading));
    final result = await _expensesRepository.getAllExpenses();
    result.fold(
      (error) => emit(
        state.copyWith(
          expensesStatus: ExpensesStatus.error,
          error: error,
        ),
      ),
      (list) {
        final newList = list.where((element) {
          final date = DateTime.parse(element.createdAt!);
          return date.isAfter(event.start ?? state.startExpenses) &&
              date.isBefore(event.end ?? state.endExpenses);
        }).toList();

        // Sumar los montos de newList

        final totalGastos = newList.fold<double>(
          0,
          (previousValue, element) =>
              previousValue + double.parse(element.monto ?? '0.00'),
        );

        emit(
          state.copyWith(
            expensesStatus: ExpensesStatus.loaded,
            listExpenses: newList,
            startExpenses: event.start ?? state.startExpenses,
            endExpenses: event.end ?? state.endExpenses,
            totalGastos: totalGastos,
          ),
        );
      },
    );
  }

  Future<void> _onSaveExpense(
    SaveExpense event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(
      state.copyWith(
        expensesStatus: ExpensesStatus.loading,
      ),
    );

    final result = await _expensesRepository.createExpense(
      id: event.usuarioId,
      obs: event.obs,
      monto: double.parse(event.monto),
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          expensesStatus: ExpensesStatus.failure,
          error: error,
        ),
      ),
      (success) => emit(
        state.copyWith(
          expensesStatus: ExpensesStatus.success,
        ),
      ),
    );
  }

  Future<void> _onGetCashExpensesStatus(
    GetCashExpensesStatus event,
    Emitter<ExpensesState> emit,
  ) async {
    final result = await _cajaRepository.getCajaOfTheDay();
    result.fold(
      // Error
      (left) => emit(
        state.copyWith(
          openBox: true,
        ),
      ),
      // Success
      (rigth) => emit(
        state.copyWith(
          openBox: rigth == null ? true : false,
        ),
      ),
    );
  }
}
