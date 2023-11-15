import 'package:casa_empenio_pe/domain/auth/auth.dart';
import 'package:casa_empenio_pe/domain/preferences/preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required UserRepository userRepository,
    required Preferences preferences,
  })  : _userRepository = userRepository,
        _preferences = preferences,
        super(AuthInitial()) {
    on<LogIn>(_onLogIn);
    on<SignOff>(_onSignOff);
    on<GetSession>(_onGetSession);
  }

  final UserRepository _userRepository;
  final Preferences _preferences;

  Future<void> _onLogIn(LogIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _userRepository.logIn(
      email: event.username,
      password: event.password,
    );

    result.fold(
      (error) => emit(AuthError(message: error)),
      (user) async {
        _preferences.setToken(user);
        emit(Authenticated(user: user));
      },
    );
  }

  Future<void> _onSignOff(SignOff event, Emitter<AuthState> emit) async {
    await _preferences.removeToken();
    emit(UnAuthenticated());
  }

  Future<void> _onGetSession(GetSession event, Emitter<AuthState> emit) async {
    await Future.delayed(const Duration(seconds: 2), () {});
    final token = _preferences.token;
    if (token == null) {
      emit(UnAuthenticated());
    } else {
      emit(Authenticated(user: token));
    }
  }
}
