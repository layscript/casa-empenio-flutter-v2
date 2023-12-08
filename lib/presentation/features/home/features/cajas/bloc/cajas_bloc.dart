import 'dart:async';

import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/domain/caja/caja_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'cajas_event.dart';
part 'cajas_state.dart';

class CajasBloc extends Bloc<CajasEvent, CajasState> {
  CajasBloc({
    required CajaRepository cajaRepository,
  })  : _cajaRepository = cajaRepository,
        super(const CajasState()) {
    on<GetAllCajas>(_onGetAllCajas);
    on<GetCajasOfTheDay>(_onGetCajasOfTheDay);
    on<CloseBox>(_onCloseBox);
    on<OpenBox>(_onOpenBox);
  }

  final CajaRepository _cajaRepository;

  Future<void> _onGetAllCajas(
    GetAllCajas event,
    Emitter<CajasState> emit,
  ) async {
    emit(state.copyWith(cajasStatus: CajasStatus.loading));

    final result = await Future.wait([
      _cajaRepository.getAllCajas(),
      _cajaRepository.getCajaOfTheDay(),
    ]);

    final firstResult = result[0] as Either<String, List<CajaEntity>>;
    final secondResult = result[1] as Either<String, CajaEntity>;

    firstResult.fold(
      (error) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.error,
          error: error,
        ),
      ),
      (list) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.loaded,
          listCajas: list,
          error: null,
        ),
      ),
    );

    secondResult.fold(
      (error) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.error,
          error: error,
        ),
      ),
      (movements) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.loaded,
          movements: movements,
          error: null,
        ),
      ),
    );
  }

  Future<void> _onGetCajasOfTheDay(
    GetCajasOfTheDay event,
    Emitter<CajasState> emit,
  ) async {
    emit(state.copyWith(cajasStatus: CajasStatus.loading));
    final result = await _cajaRepository.getCajaOfTheDay();
    result.fold(
      (error) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.error,
          error: error,
        ),
      ),
      (movements) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.loaded,
          movements: movements,
          error: null,
        ),
      ),
    );
  }

  Future<void> _onCloseBox(
    CloseBox event,
    Emitter<CajasState> emit,
  ) async {
    emit(
      state.copyWith(
        cajasStatus: CajasStatus.loading,
        movements: state.movements,
      ),
    );
    final result = await _cajaRepository.closeCaja(
      userId: event.id,
      monto: double.parse(event.monto),
      obs: event.obs,
    );

    if (result) {
      emit(
        state.copyWith(
          cajasStatus: CajasStatus.success,
        ),
      );
    } else {
      emit(
        state.copyWith(
          cajasStatus: CajasStatus.failure,
        ),
      );
    }
  }

  Future<void> _onOpenBox(
    OpenBox event,
    Emitter<CajasState> emit,
  ) async {
    emit(
      state.copyWith(
        cajasStatus: CajasStatus.loading,
        movements: state.movements,
      ),
    );
    final result = await _cajaRepository.openCaja(
      userId: event.id,
      monto: double.parse(event.monto),
      obs: event.obs,
    );

    if (result) {
      emit(
        state.copyWith(
          cajasStatus: CajasStatus.success,
          movements: state.movements,
          error: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          cajasStatus: CajasStatus.failure,
          movements: state.movements,
          error: null,
        ),
      );
    }
  }
}
