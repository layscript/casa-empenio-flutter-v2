part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LogIn extends AuthEvent {
  const LogIn({
    required this.username,
    required this.password,
  });
  final String username;
  final String password;
}

class SignOff extends AuthEvent {}

class GetSession extends AuthEvent {}

class RefreshDataUser extends AuthEvent {}

/// Solo administrador: trabajar en otra sucursal sin cerrar sesión.
class CambiarSucursal extends AuthEvent {
  const CambiarSucursal(this.sucursal);
  final SucursalEntity sucursal;

  @override
  List<Object> get props => [sucursal];
}
