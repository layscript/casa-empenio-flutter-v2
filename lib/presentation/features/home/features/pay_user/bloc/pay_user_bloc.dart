import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'pay_user_event.dart';
part 'pay_user_state.dart';

class PayUserBloc extends Bloc<PayUserEvent, PayUserState> {
  PayUserBloc({
    required MotionRepository motionRepository,
    required CajaRepository cajaRepository,
  })  : _motionRepository = motionRepository,
        _cajaRepository = cajaRepository,
        super(const PayUserState()) {
    on<GetPayExpenses>(_onGetExpenses);
    on<SavePayExpense>(_onSaveExpense);
    on<GetCashPayExpensesStatus>(_onGetCashExpensesStatus);
  }

  final MotionRepository _motionRepository;
  final CajaRepository _cajaRepository;

  Future<void> _onGetExpenses(
    GetPayExpenses event,
    Emitter<PayUserState> emit,
  ) async {
    emit(state.copyWith(payUserStatus: PayUserStatus.loading));
    final result = await _motionRepository.getAllMotions();
    result.fold(
      (error) => emit(
        state.copyWith(
          payUserStatus: PayUserStatus.error,
          error: error,
        ),
      ),
      (list) {
        final filterPayUsers = list.where((e) => e.tipo?.id == 8).toList();
        emit(
          state.copyWith(
            payUserStatus: PayUserStatus.loaded,
            listPayments: filterPayUsers,
          ),
        );
      },
    );
  }

  Future<void> _onSaveExpense(
    SavePayExpense event,
    Emitter<PayUserState> emit,
  ) async {
    print('asdadsasd: ${event.usuarioId}');

    emit(
      state.copyWith(
        payUserStatus: PayUserStatus.loading,
      ),
    );

    final result = await _motionRepository.createMotion(
      idType: event.typeId,
      idUser: event.usuarioId,
      obs: event.obs,
      monto: double.parse(event.monto),
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          payUserStatus: PayUserStatus.failure,
          error: error,
        ),
      ),
      (success) => emit(
        state.copyWith(
          payUserStatus: PayUserStatus.success,
        ),
      ),
    );
  }

  Future<void> _onGetCashExpensesStatus(
    GetCashPayExpensesStatus event,
    Emitter<PayUserState> emit,
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
