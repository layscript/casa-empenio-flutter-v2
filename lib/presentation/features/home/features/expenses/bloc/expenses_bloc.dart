import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

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
    required Preferences preferences,
  })  : _expensesRepository = expensesRepository,
        _cajaRepository = cajaRepository,
        _preferences = preferences,
        super(_initialState) {
    on<GetExpenses>(_onGetExpenses);
    on<SaveExpense>(_onSaveExpense);
    on<GetCashExpensesStatus>(_onGetCashExpensesStatus);
    on<DeleteExpense>(_onDeleteExpense);
  }

  final ExpensesRepository _expensesRepository;
  final CajaRepository _cajaRepository;
  final Preferences _preferences;

  Future<void> _onGetExpenses(
    GetExpenses event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(state.copyWith(expensesStatus: ExpensesStatus.loading));
    final result = await _expensesRepository.getAllExpenses(
      fechaInicio: event.start ?? state.startExpenses,
      fechafin: event.end ?? state.endExpenses,
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          expensesStatus: ExpensesStatus.error,
          error: error,
        ),
      ),
      (list) {
        // Sumar los montos de newList
        final totalGastos = list.fold<double>(
          0,
          (previousValue, element) =>
              previousValue + double.parse(element.monto ?? '0.00'),
        );

        emit(
          state.copyWith(
            expensesStatus: ExpensesStatus.loaded,
            listExpenses: list,
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

    List<String> images = [];

    if (event.imagenes != null) {
      for (var img in event.imagenes!) {
        final url = await _expensesRepository.createImage(path: img.path);
        url.fold(
          (error) => emit(
            state.copyWith(
              expensesStatus: ExpensesStatus.failure,
              error: error,
            ),
          ),
          (success) => images.add(success),
        );
      }

      if (images.isNotEmpty) {
        final result = await _expensesRepository.createExpense(
          id: event.usuarioId,
          obs: event.obs,
          monto: double.parse(event.monto),
          url: images.map((e) {
            return {'url': e};
          }).toList(),
          sucursalId: _preferences.token?.sucursal?.id ?? 1,
          medioPago: event.medioPago,
          banco: event.banco,
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
    }

    /* emit(
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
    ); */
  }

  Future<void> _onGetCashExpensesStatus(
    GetCashExpensesStatus event,
    Emitter<ExpensesState> emit,
  ) async {
    final result = await _cajaRepository.getCajaOfTheDay(
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
    );
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

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(
      state.copyWith(
        expensesStatus: ExpensesStatus.loading,
      ),
    );

    final result = await _expensesRepository.deleteExpense(id: event.id);
    result.fold(
      (error) => emit(
        state.copyWith(
          expensesStatus: ExpensesStatus.failure,
          error: error,
        ),
      ),
      (success) {
        add(
          GetExpenses(
            start: state.startExpenses,
            end: state.endExpenses,
          ),
        );
      },
    );
  }
}
