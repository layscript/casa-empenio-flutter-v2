import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'loans_event.dart';
part 'loans_state.dart';

class LoansBloc extends Bloc<LoansEvent, LoansState> {
  LoansBloc() : super(LoansInitial()) {
    on<GetLoans>(_onGetLoans);
  }

  Future<void> _onGetLoans(
    GetLoans event,
    Emitter<LoansState> emit,
  ) async {
    emit(LoansLoading());

    await Future.delayed(const Duration(seconds: 2), () {});

    emit(const LoansLoaded([]));
  }
}
