import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

part 'loans_event.dart';
part 'loans_state.dart';

class LoansBloc extends Bloc<LoansEvent, LoansState> {
  LoansBloc({
    required CustomerRepository customerRepository,
    required LoansRepository loansRepository,
    required CajaRepository cajaRepository,
  })  : _customerRepository = customerRepository,
        _loansRepository = loansRepository,
        _cajaRepository = cajaRepository,
        super(const LoansState()) {
    on<GetLoansInitial>((event, emit) => emit(const LoansState()));
    on<GetCashStatus>(_onGetCashStatus);
    on<ChangeTypeSearch>(
        (event, emit) => emit(state.copyWith(typeSearch: event.value)));
    on<GetLoansByDni>(_onGetLoansByDni);
    on<GetLoansByText>(_onGetLoansByText);

    on<GetDataSunatByDni>(_onGetDataSunatByDni);
    on<GetDetailsLoan>(_onGetDetailsLoan);
    on<SavePaymentLoan>(_onSavePaymentLoan);
    on<SaveSettlementLoan>(_onSaveSettlementLoan);
    on<AddAmountLoan>(_onAddAmountLoan);
    on<CreateInvoiceLoans>(_onCreateInvoiceLoans);

    on<GetLoansSearchByDni>(_onGetLoansSearchByDni);
  }

  final CustomerRepository _customerRepository;
  final LoansRepository _loansRepository;
  final CajaRepository _cajaRepository;

  LoansState get _loadingState =>
      state.copyWith(loansStatus: LoansStatus.loading);

  LoansState _successState(CustomerEntity customer) => state.copyWith(
        loansStatus: LoansStatus.loaded,
        customer: customer,
      );

  LoansState _errorState(String message) => state.copyWith(
        loansStatus: LoansStatus.error,
        error: message,
      );

  Future<void> _onGetLoansByDni(
    GetLoansByDni event,
    Emitter<LoansState> emit,
  ) async {
    if (state.isLoansLoading == true) return;
    //emit(_loadingState);
    emit(
      state.copyWith(
        loansStatus: LoansStatus.loading,
        searchText: event.value,
      ),
    );
    final result = await _customerRepository.getCustomerByDni(
      dni: event.value,
    );
    result.fold(
      (message) => emit(_errorState(message)),
      (customer) => emit(_successState(customer)),
    );
  }

  Future<void> _onGetLoansByText(
    GetLoansByText event,
    Emitter<LoansState> emit,
  ) async {
    if (state.isLoansLoading == true) return;
    //emit(_loadingState);
    emit(
      state.copyWith(
        loansStatus: LoansStatus.loading,
        searchText: event.value,
      ),
    );
    final result = await _loansRepository.getLoans(
      criterio: event.value,
    );
    result.fold(
      (message) => emit(_errorState(message)),
      (loans) {
        print('skjladajlsdkjlasaljksd 3: ${loans.length}');
        emit(
          _successState(
            CustomerEntity(
              dni: null,
              nombres: null,
              apellidos: null,
              domicilio: null,
              email: null,
              celular: null,
              prestamos: loans,
              prestamosAval: loans,
              pagos: null,
              ventas: null,
              updatedAt: null,
              createdAt: null,
              imagenDos: '', // TODO :: HACERERER
              imagenUno: '',
            ),
          ),
        ); /* emit(_successState(customer)) */
      },
    );
  }

  Future<void> _onGetDetailsLoan(
    GetDetailsLoan event,
    Emitter<LoansState> emit,
  ) async {
    //if (state.isLoansLoading) return;
    emit(
      state.copyWith(
        loansStatus: LoansStatus.loadingDetailsLoan,
      ),
    );
    final result = await _loansRepository.getLoan(id: event.value);
    result.fold(
      (message) => emit(
        _errorState(message),
      ),
      (data) {
        emit(
          state.copyWith(
            loansStatus: LoansStatus.loaded,
            loanDetails: data,
          ),
        );
      },
    );
  }

  Future<void> _onGetDataSunatByDni(
    GetDataSunatByDni event,
    Emitter<LoansState> emit,
  ) async {
    if (event.value?.length == 8) {
      emit(state.copyWith(loansStatus: LoansStatus.loadingDetailsSunat));
      final result = await _customerRepository.getCustomerSunatByDni(
        dni: event.value ?? '',
        //dni: '00000000',
      );
      result.fold(
        (message) {
          emit(_errorState(message));
        },
        (customerSunat) {
          emit(
            state.copyWith(
              loansStatus: LoansStatus.loaded,
              customerSunat: customerSunat,
            ),
          );
        },
      );
    }
  }

  Future<void> _onSavePaymentLoan(
    SavePaymentLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(_loadingState);
    final resultPayment = await _loansRepository.savePayment(
      codigo: event.idPrestamo,
      monto: double.parse(event.monto),
      userId: event.userId,
    );

    if (resultPayment) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.paymentSuccess,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.paymentError,
        ),
      );
    }
  }

  Future<void> _onSaveSettlementLoan(
    SaveSettlementLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(_loadingState);
    final resultPayment = await _loansRepository.savePayment(
      codigo: event.idPrestamo,
      monto: double.parse(event.monto),
      userId: event.userId,
    );

    final resultLoand = await _loansRepository.payOffLoan(
      id: event.codigo,
    );

    if (resultPayment && resultLoand) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.settlementSuccess,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.settlementError,
        ),
      );
    }
  }

  Future<void> _onAddAmountLoan(
    AddAmountLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(_loadingState);
    final result = await _loansRepository.addAmountLoan(
      codigo: event.idPrestamo,
      monto: event.monto,
      observaciones: event.obs,
    );
    if (result) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.addAmountSuccess,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.addAmountError,
        ),
      );
    }
  }

  Future<void> _onCreateInvoiceLoans(
    CreateInvoiceLoans event,
    Emitter<LoansState> emit,
  ) async {
    emit(
      state.copyWith(
        loansStatus: LoansStatus.electronicTicketLoading,
      ),
    );

    final result = await _loansRepository.createInvoceLoans(
      dni: event.dni,
      fullName: event.fullName,
      direccion: event.direccion,
      idPrestamo: event.idPrestamo,
    );

    if (result) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.electronicTicketSuccess,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.electronicTicketError,
        ),
      );
    }
  }

  Future<void> _onGetCashStatus(
    GetCashStatus event,
    Emitter<LoansState> emit,
  ) async {
    // Llamar api de caja y verificar que exista algun registro.
    emit(state.copyWith(loansStatus: LoansStatus.loading));
    final result = await _cajaRepository.getCajaOfTheDay();
    result.fold(
      // Error
      (left) => emit(
        state.copyWith(
          openBox: true,
          loansStatus: LoansStatus.loaded,
        ),
      ),
      // Success
      (rigth) => emit(
        state.copyWith(
          openBox: false,
          loansStatus: LoansStatus.loaded,
        ),
      ),
    );

    // Mostrar modal o dejar pasar
  }

  Future<void> _onGetLoansSearchByDni(
    GetLoansSearchByDni event,
    Emitter<LoansState> emit,
  ) async {
    emit(
      state.copyWith(
        loansSearchStatus: LoansStatus.searchClientLoading,
      ),
    );

    final result = await _customerRepository.getCustomerByDni(
      dni: event.value,
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          loansSearchStatus: LoansStatus.searchClientError,
        ),
      ),
      (customer) => emit(
        state.copyWith(
          loansSearchStatus: LoansStatus.searchClientSuccess,
          searchCustomer: customer,
        ),
      ),
    );
  }
}
