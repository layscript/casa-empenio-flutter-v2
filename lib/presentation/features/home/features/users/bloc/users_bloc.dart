import 'dart:async';

import 'package:casa_empenio_pe/domain/auth/auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(UsersInitial()) {
    on<GetUsers>(_onGetUsers);
    on<SaveUser>(_onSaveUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  final UserRepository _userRepository;

  Future<void> _onGetUsers(
    GetUsers event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());

    final result = await _userRepository.getUsers(
      limit: 100,
      offset: 0,
    );

    result.fold(
      (error) {
        emit(UsersError(error));
      },
      (users) {
        emit(UsersLoaded(users));
      },
    );
  }

  Future<void> _onSaveUser(
    SaveUser event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());

    final result = await _userRepository.createUser(
      id: 0,
      nombre: event.fullNames,
      apellido: event.fullLastNames,
      userName: event.username,
      email: event.email,
      celular: 0,
      rolId: 2,
      password: event.password,
    );

    result.fold(
      (error) {
        emit(UsersError(error));
      },
      (users) {
        add(GetUsers());
      },
    );
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    final result = await _userRepository.updateUser(
      id: event.id,
      nombre: event.fullNames,
      apellido: event.fullLastNames,
      userName: event.username,
      email: event.email,
      celular: event.celular,
      rolId: event.rolId,
      password: event.password,
    );

    result.fold(
      (error) {
        emit(UsersError(error));
      },
      (users) {
        add(GetUsers());
      },
    );
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    final result = await _userRepository.deleteUser(
      idUser: event.id,
    );
    result.fold(
      (message) {
        emit(UsersError(message));
      },
      (success) {
        add(GetUsers());
      },
    );
  }
}
