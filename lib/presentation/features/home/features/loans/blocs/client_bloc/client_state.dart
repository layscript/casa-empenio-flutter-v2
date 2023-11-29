part of 'client_bloc.dart';

sealed class ClientState extends Equatable {
  const ClientState();
}

final class ClientInitial extends ClientState {
  @override
  List<Object?> get props => [];
}

final class ClientLoading extends ClientState {
  @override
  List<Object?> get props => [];
}

final class ClientLoaded extends ClientState {
  const ClientLoaded({
    required this.customer,
    required this.filterCustomer,
  });
  final List<CustomerEntity> customer;
  final List<CustomerEntity> filterCustomer;

  ClientLoaded copyWith({
    List<CustomerEntity>? customer,
    List<CustomerEntity>? filterCustomer,
  }) =>
      ClientLoaded(
        filterCustomer: filterCustomer ?? this.filterCustomer,
        customer: customer ?? this.customer,
      );

  String fullNames(CustomerEntity client) {
    return '${client.nombres} ${client.apellidos}';
  }

  @override
  List<Object?> get props => [customer, filterCustomer];
}

final class ClientError extends ClientState {
  const ClientError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
