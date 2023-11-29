part of 'client_bloc.dart';

sealed class ClientEvent extends Equatable {
  const ClientEvent();

  @override
  List<Object> get props => [];
}

class GetClients extends ClientEvent {}

class SearchClientByText extends ClientEvent {
  const SearchClientByText(this.value);
  final String value;
}
