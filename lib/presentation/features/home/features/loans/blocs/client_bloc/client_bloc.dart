import 'dart:async';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  ClientBloc({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository,
        super(ClientInitial()) {
    on<GetClients>(_onGetClients);
    on<SearchClientByText>(_onSearchClientByText);
  }

  final CustomerRepository _customerRepository;

  Future<void> _onGetClients(
    GetClients event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientLoading());
    final result = await _customerRepository.getCustomers();
    result.fold(
      (message) => emit(ClientError(message)),
      (customer) => emit(
        ClientLoaded(
          customer: customer,
          filterCustomer: customer,
        ),
      ),
    );
  }

  void _onSearchClientByText(
    SearchClientByText event,
    Emitter<ClientState> emit,
  ) {
    final data = state as ClientLoaded;
    if (event.value.isEmpty) {
      emit(data.copyWith(customer: data.filterCustomer));
    } else {
      final filterCustomer = data.customer
          .where((element) => element.nombres!
              .toUpperCase()
              .contains(event.value.toUpperCase()))
          .toList();

      emit(data.copyWith(customer: filterCustomer));
    }
  }
}
