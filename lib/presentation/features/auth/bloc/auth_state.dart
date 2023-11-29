part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class Authenticated extends AuthState {
  const Authenticated({required this.user});
  final UserEntity user;
}

final class UnAuthenticated extends AuthState {}

final class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;
}
