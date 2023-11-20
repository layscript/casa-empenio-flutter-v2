part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

class GetUsers extends UsersEvent {}

class SaveUser extends UsersEvent {
  const SaveUser({
    required this.fullNames,
    required this.fullLastNames,
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  final String fullNames;
  final String fullLastNames;
  final String email;
  final String username;
  final String password;
  final String confirmPassword;
}

class UpdateUser extends UsersEvent {
  const UpdateUser({
    required this.id,
    required this.fullNames,
    required this.fullLastNames,
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.celular,
    required this.rolId,
  });

  final int id;
  final String fullNames;
  final String fullLastNames;
  final String email;
  final String username;
  final String password;
  final String confirmPassword;
  final int celular;
  final int rolId;
}

class DeleteUser extends UsersEvent {
  const DeleteUser({required this.id});
  final int id;
}
