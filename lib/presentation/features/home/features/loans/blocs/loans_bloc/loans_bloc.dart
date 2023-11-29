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
  })  : _customerRepository = customerRepository,
        _loansRepository = loansRepository,
        super(const LoansState()) {
    on<GetLoansInitial>((event, emit) => emit(const LoansState()));
    on<GetLoansByDni>(_onGetLoansByDni);
    on<GetDataSunatByDni>(_onGetDataSunatByDni);
    on<GetDetailsLoan>(_onGetDetailsLoan);
    on<SavePaymentLoan>(_onSavePaymentLoan);
    on<SaveSettlementLoan>(_onSaveSettlementLoan);
    on<AddAmountLoan>(_onAddAmountLoan);
    on<CreateInvoiceLoans>(_onCreateInvoiceLoans);
  }

  final CustomerRepository _customerRepository;
  final LoansRepository _loansRepository;

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
    emit(_loadingState);
    final result = await _customerRepository.getCustomerByDni(dni: event.value);
    result.fold(
      (message) => emit(_errorState(message)),
      (customer) => emit(_successState(customer)),
    );
  }

  Future<void> _onGetDetailsLoan(
    GetDetailsLoan event,
    Emitter<LoansState> emit,
  ) async {
    //if (state.isLoansLoading) return;
    emit(state.copyWith(loansStatus: LoansStatus.loadingDetailsLoan));
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
    /*  await _loansRepository.savePayment(
      codigo: event.idPrestamo,
      monto: double.parse(
        event.monto,
      ),
      userId: event.userId,
    ); */
    emit(_loadingState);
    await Future.delayed(const Duration(seconds: 3), () {});
    emit(
      state.copyWith(
        loansStatus: LoansStatus.paymentSuccess,
      ),
    );
    /* emit(
      state.copyWith(
        loansStatus: LoansStatus.paymentError,
      ),
    ); */
  }

  Future<void> _onSaveSettlementLoan(
    SaveSettlementLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(_loadingState);
    await Future.delayed(const Duration(seconds: 3), () {});
    /* emit(
      state.copyWith(
        loansStatus: LoansStatus.settlementSuccess,
      ),
    ); */
    emit(
      state.copyWith(
        loansStatus: LoansStatus.settlementError,
      ),
    );
  }

  Future<void> _onAddAmountLoan(
    AddAmountLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(_loadingState);
    await Future.delayed(const Duration(seconds: 3), () {});
    emit(
      state.copyWith(
        loansStatus: LoansStatus.addAmountSuccess,
      ),
    );
  }

  Future<void> _onCreateInvoiceLoans(
    CreateInvoiceLoans event,
    Emitter<LoansState> emit,
  ) async {}
}
