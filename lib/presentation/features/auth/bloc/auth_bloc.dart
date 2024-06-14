import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required UserRepository userRepository,
    required Preferences preferences,
    required ModulosRepository modulosRepository,
  })  : _userRepository = userRepository,
        _preferences = preferences,
        _modulosRepository = modulosRepository,
        super(const AuthInitial()) {
    on<LogIn>(_onLogIn);
    on<SignOff>(_onSignOff);
    on<GetSession>(_onGetSession);
    on<RefreshDataUser>(_onRefreshDataUser);
  }

  final UserRepository _userRepository;
  final ModulosRepository _modulosRepository;
  final Preferences _preferences;
  Future<void> _onLogIn(LogIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _userRepository.logIn(
      email: event.username,
      password: event.password,
    );

    await result.fold(
      (error) async {
        if (!emit.isDone) emit(AuthError(message: error));
      },
      (user) async {
        final modules = await _modulosRepository.getAllModulos(
          limit: 100,
        );

        await modules.fold(
          (error) async {
            if (!emit.isDone) emit(AuthError(message: error));
          },
          (modulos) async {
            _preferences.setToken(user);
            if (!emit.isDone) {
              emit(
                Authenticated(
                  user,
                  modulos,
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _onSignOff(SignOff event, Emitter<AuthState> emit) async {
    await _preferences.removeToken();
    emit(const UnAuthenticated());
  }

  Future<void> _onGetSession(GetSession event, Emitter<AuthState> emit) async {
    await Future.delayed(const Duration(seconds: 2), () {});
    final token = _preferences.token;
    if (token == null) {
      emit(const UnAuthenticated());
    } else {
      emit(
        Authenticated(
          token,
          state.modulos ?? [],
        ),
      );
    }
  }

  Future<void> _onRefreshDataUser(
    RefreshDataUser event,
    Emitter<AuthState> emit,
  ) async {
    //emit(AuthLoading());
    //await Future.delayed(const Duration(milliseconds: 200), () {});
    if (_preferences.refresh == true) {
      final result = await _userRepository.getUser(
        id: _preferences.token?.id ?? 1,
      );

      result.fold(
        (error) async {
          _preferences.removeToken();
          emit(const UnAuthenticated());
        },
        (user) async {
          _preferences.setToken(user);
          _preferences.setRefresh(false);
          emit(
            Authenticated(
              user,
              state.modulos ?? [],
            ),
          );
        },
      );
    }
  }
}
