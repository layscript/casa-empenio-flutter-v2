import 'dart:async';

import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/domain/caja/caja_repository.dart';
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
    on<IncreaseBox>(_onIncreaseBox);
  }

  final CajaRepository _cajaRepository;

  Future<void> _onGetAllCajas(
    GetAllCajas event,
    Emitter<CajasState> emit,
  ) async {
    emit(state.copyWith(cajasStatus: CajasStatus.loading));

    /*   final result = await Future.wait([
      _cajaRepository.getAllCajas(),
      _cajaRepository.getCajaOfTheDay(),
    ]);

    final firstResult = result[0] as Either<String, List<CajaEntity>>;
    final secondResult = result[1] as Either<String, CajaEntity>; */

    final firstResult = await _cajaRepository.getAllCajas();

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
          listCajas: list.where((e) => e.estado != 'Abierta').toList(),
          error: null,
        ),
      ),
    );

    /*  secondResult.fold(
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
    ); */
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

    result.fold(
      (error) => emit(
        state.copyWith(
          error: error,
          cajasStatus: CajasStatus.failure,
        ),
      ),
      (success) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.success,
        ),
      ),
    );
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

    result.fold(
      (error) => emit(
        state.copyWith(
          error: error,
          cajasStatus: CajasStatus.failure,
          movements: state.movements,
        ),
      ),
      (success) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.success,
          movements: state.movements,
        ),
      ),
    );
  }

  Future<void> _onIncreaseBox(
    IncreaseBox event,
    Emitter<CajasState> emit,
  ) async {
    emit(
      state.copyWith(
        cajasStatus: CajasStatus.loading,
        movements: state.movements,
      ),
    );
    final result = await _cajaRepository.aumentarMonto(
      userId: event.id,
      monto: double.parse(event.monto),
      obs: event.obs,
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          error: error,
          cajasStatus: CajasStatus.failure,
          movements: state.movements,
        ),
      ),
      (success) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.success,
          movements: state.movements,
        ),
      ),
    );

    /* Future.delayed(const Duration(seconds: 2), () {});
    emit(
      state.copyWith(
        cajasStatus: CajasStatus.success,
        movements: state.movements,
      ),
    ); */
  }
}
