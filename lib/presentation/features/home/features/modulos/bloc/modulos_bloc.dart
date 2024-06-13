import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'modulos_event.dart';
part 'modulos_state.dart';

class ModulosBloc extends Bloc<ModulosEvent, ModulosState> {
  ModulosBloc({required ModulosRepository modulosRepository})
      : _modulosRepository = modulosRepository,
        super(const ModulosState()) {
    on<GetModulos>(_onGetModulos);
    on<SearchModuloByName>(_onSearchModuloByName);
  }

  final ModulosRepository _modulosRepository;

  Future<void> _onGetModulos(
    GetModulos event,
    Emitter<ModulosState> emit,
  ) async {
    emit(state.copyWith(status: ModulosStatus.loading));
    final result = await _modulosRepository.getAllModulos();
    result.fold(
      (error) => emit(
        state.copyWith(
          status: ModulosStatus.error,
          error: error,
        ),
      ),
      (modulos) => emit(
        state.copyWith(
          status: ModulosStatus.loaded,
          listModulos: modulos,
        ),
      ),
    );
  }

  Future<void> _onSearchModuloByName(
    SearchModuloByName event,
    Emitter<ModulosState> emit,
  ) async {
    emit(state.copyWith(status: ModulosStatus.loading));
    final result = await _modulosRepository.getAllModulos(
      busqueda: event.value,
      offset: 0,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          status: ModulosStatus.error,
          error: error,
        ),
      ),
      (modulos) => emit(
        state.copyWith(
          status: ModulosStatus.loaded,
          listModulos: modulos,
        ),
      ),
    );
  }
}
