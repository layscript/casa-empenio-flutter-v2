part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.modulos,
  });
  final UserEntity? user;
  final List<ModulosEntity>? modulos;

  @override
  List<Object?> get props => [
        user,
        modulos,
      ];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  @override
  List<Object> get props => [];
}

final class Authenticated extends AuthState {
  const Authenticated(UserEntity user, List<ModulosEntity> modulos)
      : super(
          user: user,
          modulos: modulos,
        );
}

final class RecoverAuthenticated extends AuthState {
  const RecoverAuthenticated(
    UserEntity user,
  ) : super(user: user);
}

final class UnAuthenticated extends AuthState {
  const UnAuthenticated();
}

final class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;

  @override
  List<Object> get props => [message];
}
