import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'interests_event.dart';
part 'interests_state.dart';

class InterestsBloc extends Bloc<InterestsEvent, InterestsState> {
  InterestsBloc({required InterestsRepository interestsRepository})
      : _interestsRepository = interestsRepository,
        super(InterestsInitial()) {
    on<GetInterests>(_onGetInterests);
    on<SaveInterest>(_onSaveInterest);
    on<UpdateInterest>(_onUpdateInterest);
    on<DeleteInterest>(_onDeleteInterest);
  }

  final InterestsRepository _interestsRepository;

  Future<void> _onGetInterests(
    GetInterests event,
    Emitter<InterestsState> emit,
  ) async {
    emit(InterestsLoading());
    final result = await _interestsRepository.getInterest();
    result.fold(
      (message) {
        emit(InterestsError(message));
      },
      (listInterests) {
        emit(InterestsLoaded(listInterests));
      },
    );
  }

  Future<void> _onSaveInterest(
    SaveInterest event,
    Emitter<InterestsState> emit,
  ) async {
    emit(InterestsLoading());
    final result =
        await _interestsRepository.createInterests(interest: event.data);
    result.fold(
      (message) {
        emit(InterestsError(message));
      },
      (success) {
        add(GetInterests());
      },
    );
  }

  Future _onUpdateInterest(
    UpdateInterest event,
    Emitter<InterestsState> emit,
  ) async {
    emit(InterestsLoading());
    final result = await _interestsRepository.updateInterests(
      interests: Interests(
        id: event.id,
        intereses: event.data,
      ),
    );
    result.fold(
      (message) {
        emit(InterestsError(message));
      },
      (success) {
        add(GetInterests());
      },
    );
  }

  Future<void> _onDeleteInterest(
    DeleteInterest event,
    Emitter<InterestsState> emit,
  ) async {
    emit(InterestsLoading());
    final result = await _interestsRepository.deleteInterests(
      idInterest: event.id,
    );
    result.fold(
      (message) {
        emit(InterestsError(message));
      },
      (success) {
        add(GetInterests());
      },
    );
  }
}
