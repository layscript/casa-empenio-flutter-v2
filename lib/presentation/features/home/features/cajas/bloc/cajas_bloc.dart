import 'dart:async';

import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/domain/caja/caja_repository.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'cajas_event.dart';
part 'cajas_state.dart';

class CajasBloc extends Bloc<CajasEvent, CajasState> {
  CajasBloc({
    required CajaRepository cajaRepository,
    required ExpensesRepository expensesRepository,
    required Preferences preferences,
  })  : _cajaRepository = cajaRepository,
        _expensesRepository = expensesRepository,
        _preferences = preferences,
        super(const CajasState()) {
    on<GetAllCajas>(_onGetAllCajas);
    on<GetCajasOfTheDay>(_onGetCajasOfTheDay);
    on<CloseBox>(_onCloseBox);
    on<OpenBox>(_onOpenBox);
    on<IncreaseBox>(_onIncreaseBox);
    on<DeleteMovement>(_onDeleteMovement);
  }

  final CajaRepository _cajaRepository;
  final ExpensesRepository _expensesRepository;
  final Preferences _preferences;

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
      (list) {
        final filterCaja = list.where((e) => e.estado != 'Abierta').toList();

        final newFilterCaja = filterCaja.map((e) {
          final newMovements = e.movimientos!
              .where((e) =>
                  e.eliminado == false &&
                  e.observaciones?.startsWith('Eliminar') == false)
              .toList();
          return e.copyWith(movimientos: newMovements);
        }).toList();

        emit(
          state.copyWith(
            cajasStatus: CajasStatus.loaded,
            listCajas: newFilterCaja,
            error: null,
          ),
        );
      },
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
    final result = await _cajaRepository.getCajaOfTheDay(
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          cajasStatus: CajasStatus.error,
          error: error,
        ),
      ),
      (result) {
        // Traer los movimientos que eliminado sean
        CajaEntity? caja;

        if (result == null) {
          caja = null;
        } else {
          caja = result.copyWith(
              movimientos: result.movimientos!
                  .where((e) =>
                      e.eliminado == false &&
                      e.observaciones?.startsWith('Eliminar') == false)
                  .toList());
        }

        emit(
          state.copyWith(
            cajasStatus: CajasStatus.loaded,
            movements: caja,
            error: null,
          ),
        );
      },
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
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
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
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
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
    if (state.cajasStatus == CajasStatus.loading) return;

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
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
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

  Future<void> _onDeleteMovement(
    DeleteMovement event,
    Emitter<CajasState> emit,
  ) async {
    emit(
      state.copyWith(
        cajasStatus: CajasStatus.loading,
        movements: state.movements,
      ),
    );

    await _expensesRepository.deleteExpense(
      id: event.id,
    );

    emit(
      state.copyWith(
        cajasStatus: CajasStatus.success,
        movements: state.movements,
      ),
    );
    /*   final result = await _cajaRepository.deleteMovement(
      id: event.id,
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
    ); */
  }
}
