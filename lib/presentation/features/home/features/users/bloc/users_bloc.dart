import 'dart:async';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc(
      {required UserRepository userRepository,
      required SucursalRepository sucursalRepository})
      : _userRepository = userRepository,
        _sucursalRepository = sucursalRepository,
        super(const UsersState()) {
    on<GetUsers>(_onGetUsers);
    on<SaveUser>(_onSaveUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  final UserRepository _userRepository;
  final SucursalRepository _sucursalRepository;

  UsersState get _loadingState =>
      state.copyWith(userStatus: UserStatus.loading);

  UsersState _successState(
    List<UserEntity> users,
    List<SucursalEntity> listSucursales,
  ) =>
      state.copyWith(
        userStatus: UserStatus.loaded,
        listUsers: users,
        listSucursales: listSucursales,
      );

  UsersState _errorState(String message) => state.copyWith(
        userStatus: UserStatus.error,
        error: message,
      );

  Future<void> _onGetUsers(
    GetUsers event,
    Emitter<UsersState> emit,
  ) async {
    emit(_loadingState);

    final result = await _userRepository.getUsers(
      limit: 100,
      offset: 0,
    );

    await result.fold(
      (error) async => emit(_errorState(error)),
      (users) async {
        final getSucursales = await _sucursalRepository.getSucursales();
        await getSucursales.fold(
          (error) async => emit(_errorState(error)),
          (sucursales) async => emit(
            _successState(
              users,
              sucursales,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSaveUser(
    SaveUser event,
    Emitter<UsersState> emit,
  ) async {
    emit(_loadingState);

    final result = await _userRepository.createUser(
      id: 0,
      nombre: event.fullNames,
      apellido: event.fullLastNames,
      userName: event.username,
      email: event.email,
      celular: 0,
      rolId: 2,
      password: event.password,
      sucursalId: event.sucursalId,
    );

    result.fold(
      (error) {
        emit(_errorState(error));
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
    emit(_loadingState);
    final result = await _userRepository.updateUser(
      id: event.id,
      nombre: event.fullNames,
      apellido: event.fullLastNames,
      userName: event.username,
      email: event.email,
      celular: event.celular,
      rolId: event.rolId,
      password: event.password,
      sucursalId: event.sucursalId,
    );

    result.fold(
      (error) {
        emit(_errorState(error));
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
    emit(_loadingState);
    final result = await _userRepository.deleteUser(
      idUser: event.id,
    );
    result.fold(
      (message) {
        emit(_errorState(message));
      },
      (success) {
        add(GetUsers());
      },
    );
  }
}
