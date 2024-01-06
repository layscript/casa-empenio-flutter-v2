import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'historial_event.dart';
part 'historial_state.dart';

class HistorialBloc extends Bloc<HistorialEvent, HistorialState> {
  HistorialBloc({
    required UserRepository userRepository,
    required HistorialRepository historialRepository,
  })  : _userRepository = userRepository,
        _historialRepository = historialRepository,
        super(const HistorialState()) {
    on<GetAllHistorialEvent>(_onGetAllHistorialEvent);
    on<GetHistorialByDocumentEvent>(_onGetHistorialByDocumentEvent);
  }

  final UserRepository _userRepository;
  final HistorialRepository _historialRepository;

  Future<void> _onGetAllHistorialEvent(
    GetAllHistorialEvent event,
    Emitter<HistorialState> emit,
  ) async {
    emit(state.copyWith(historialStatus: HistorialStatus.loading));
    final result = await _userRepository.getUsers(
      limit: 100,
      offset: 0,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          historialStatus: HistorialStatus.error,
          error: error,
        ),
      ),
      (users) => emit(
        state.copyWith(
          historialStatus: HistorialStatus.loaded,
          listUsers: users,
        ),
      ),
    );
  }

  Future<void> _onGetHistorialByDocumentEvent(
    GetHistorialByDocumentEvent event,
    Emitter<HistorialState> emit,
  ) async {
    emit(state.copyWith(historialDetailsStatus: HistorialStatus.loading));

    final result = await _historialRepository.getHistorialByUser(
      userId: event.userId,
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          historialDetailsStatus: HistorialStatus.error,
        ),
      ),
      (listHistorial) => emit(
        state.copyWith(
          historialDetailsStatus: HistorialStatus.loaded,
          listHistorial: listHistorial,
        ),
      ),
    );
  }
}
