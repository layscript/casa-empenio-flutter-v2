import 'dart:async';
import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'reports_event.dart';
part 'reports_state.dart';

final _initialState = ReportsState(
  statusClosedLoans: ReportsStatus.initial,
  statusPayments: ReportsStatus.initial,
  statusIncreases: ReportsStatus.initial,
  statusLoans: ReportsStatus.initial,
  statusDetails: ReportsStatus.initial,
  statusCanceled: ReportsStatus.initial,
  startTimePayments: DateTime.now(),
  endTimePayments: DateTime.now(),
  startTimeContracts: DateTime.now(),
  endTimeContracts: DateTime.now(),
  listClosedLoans: const [],
  listLoans: const [],
  totalPayments: 0.0,
  listPayments: const [],
  totalIncreases: 0.0,
  totalProfits: 0.0,
  listIncrease: const [],
  totalLoans: 0.0,
  canceladoContracts: true,
  liquidadoContracts: true,
  pagadoContracts: true,
  vencidoContracts: true,
  ventaContracts: true,
  vigentContracts: true,
  loanDetails: null,
  paymentDetails: null,
);

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required ReportsRepository reportsRepository,
    required LoansRepository loansRepository,
  })  : _reportsRepository = reportsRepository,
        _loansRepository = loansRepository,
        super(_initialState) {
    on<GetLoadInitialDataPayments>(_onGetLoadInitialDataPayments);
    on<GetLoadInitialDataContracts>(_onGetLoadInitialDataContracts);
    on<GetDetailsReportLoan>(_onGetDetailsReportLoan);
    on<GetDetailsReportPay>(_onGetDetailsReportPay);
    on<CancelReportLoan>(_onCancelReportLoan);
    on<AnularPrestamoLiquidado>(_onAnularPrestamoLiquidado);

    // Tags
    on<ChangeCanceladoContracts>(
      (event, emit) => emit(state.copyWith(canceladoContracts: event.value)),
    );
    on<ChangeLiquidadoContracts>(
      (event, emit) => emit(state.copyWith(liquidadoContracts: event.value)),
    );
    on<ChangePagadoContracts>(
      (event, emit) => emit(state.copyWith(pagadoContracts: event.value)),
    );
    on<ChangeVencidoContracts>(
      (event, emit) => emit(state.copyWith(vencidoContracts: event.value)),
    );
    on<ChangeVentaContracts>(
      (event, emit) => emit(state.copyWith(ventaContracts: event.value)),
    );
    on<ChangeVigentContracts>(
      (event, emit) => emit(state.copyWith(vigentContracts: event.value)),
    );
  }

  final LoansRepository _loansRepository;
  final ReportsRepository _reportsRepository;

  Future<void> _onGetLoadInitialDataPayments(
    GetLoadInitialDataPayments event,
    Emitter<ReportsState> emit,
  ) async {
    emit(
      state.copyWith(
        statusClosedLoans: ReportsStatus.loading,
        statusPayments: ReportsStatus.loading,
        startTimePayments: event.start,
        endTimePayments: event.end,
      ),
    );

    final result = await Future.wait([
      _reportsRepository.getClosedByRangeDate(
        inicio: event.start ?? state.startTimePayments,
        fin: event.end ?? state.endTimePayments,
      ),
      _reportsRepository.getPaymentsByRangeDate(
        inicio: event.start ?? state.startTimePayments,
        fin: event.end ?? state.endTimePayments,
      ),
      _reportsRepository.getLoansByRangeDate(
        inicio: event.start ?? state.startTimePayments,
        fin: event.end ?? state.endTimePayments,
      ),
    ]);

    final responseClosedByRangeDate =
        result[0] as Either<String, List<LoansEntity>>;
    responseClosedByRangeDate.fold(
      (message) {
        emit(state.copyWith(
          statusClosedLoans: ReportsStatus.error,
        ));
      },
      (listLoans) {
        emit(state.copyWith(
          listClosedLoans: listLoans,
          statusClosedLoans: ReportsStatus.success,
        ));
      },
    );

    final responsePaymentsByRangeDate =
        result[1] as Either<String, List<ReportsPaymentEntity>>;
    responsePaymentsByRangeDate.fold(
      (message) {
        emit(state.copyWith(
          statusPayments: ReportsStatus.error,
        ));
      },
      (listPayments) {
        double monto = 0.0;
        if (listPayments.isNotEmpty) {
          for (var element in listPayments) {
            monto += double.parse(element.monto ?? '0.00');
          }
        }

        emit(state.copyWith(
          listPayments: listPayments,
          totalPayments: monto,
          statusPayments: ReportsStatus.success,
        ));
      },
    );

    final responseLoansByRangeDate =
        result[2] as Either<String, List<LoansEntity>>;

    responseLoansByRangeDate.fold(
      (message) => null,
      (listLoans) {
        final prestamos = listLoans.where((element) {
          if (element.estado == 'VIGENTE' && state.vigentContracts) {
            return true;
          } else if (element.estado == 'PAGADO' && state.pagadoContracts) {
            return true;
          } else if (element.estado == 'VENCIDO' && state.vencidoContracts) {
            return true;
          } else if (element.estado == 'VENTA' && state.ventaContracts) {
            return true;
          } else if (element.estado == 'CANCELADO' &&
              state.canceladoContracts) {
            return true;
          } else if (element.estado == 'LIQUIDADO' &&
              state.liquidadoContracts) {
            return true;
          } else {
            return false;
          }
        }).toList();

        emit(
          state.copyWith(
            listLoans: prestamos,
            //status: ReportsStatus.success,
          ),
        );
      },
    );
  }

  Future<void> _onGetLoadInitialDataContracts(
    GetLoadInitialDataContracts event,
    Emitter<ReportsState> emit,
  ) async {
    emit(
      state.copyWith(
        statusIncreases: ReportsStatus.loading,
        statusLoans: ReportsStatus.loading,
        statusCanceled: ReportsStatus.initial,
        startTimeContracts: event.start,
        endTimeContracts: event.end,
      ),
    );

    final result = await Future.wait([
      _reportsRepository.getLoansByRangeDate(
        inicio: event.start ?? state.startTimeContracts,
        fin: event.end ?? state.endTimeContracts,
      ),
      _reportsRepository.getIncreasesByRangeDate(
        inicio: event.start ?? state.startTimeContracts,
        fin: event.end ?? state.endTimeContracts,
      ),
    ]);

    final responseLoansByRangeDate =
        result[0] as Either<String, List<LoansEntity>>;

    responseLoansByRangeDate.fold(
      (message) => null,
      (listLoans) {
        final prestamos = listLoans.where((element) {
          if (element.estado == 'VIGENTE' && state.vigentContracts) {
            return true;
          } else if (element.estado == 'PAGADO' && state.pagadoContracts) {
            return true;
          } else if (element.estado == 'VENCIDO' && state.vencidoContracts) {
            return true;
          } else if (element.estado == 'VENTA' && state.ventaContracts) {
            return true;
          } else if (element.estado == 'CANCELADO' &&
              state.canceladoContracts) {
            return true;
          } else if (element.estado == 'LIQUIDADO' &&
              state.liquidadoContracts) {
            return true;
          } else {
            return false;
          }
        }).toList();

        double totalLoans = 0.0;
        double totalProfits = 0.0;

        if (prestamos.isNotEmpty) {
          for (var element in prestamos) {
            if (element.estado != 'CANCELADO') {
              // Ganancia totales
              totalProfits += double.parse(element.ganancia ?? '0.00');
              // Prestamos totales
              totalLoans += double.parse(element.monto ?? '0.00');
            }
          }
        }

        emit(
          state.copyWith(
            listLoans: prestamos,
            totalLoans: totalLoans,
            totalProfits: totalProfits,
            statusLoans: ReportsStatus.success,
          ),
        );
      },
    );

    final responseIncreasesByRangeDate =
        result[1] as Either<String, List<ReportsContractsEntity>>;

    responseIncreasesByRangeDate.fold(
      (l) {},
      (listIncrease) {
        double totalIncreases = 0.0;
        if (listIncrease.isNotEmpty) {
          for (var element in listIncrease) {
            totalIncreases += double.parse(element.monto ?? '0.00');
          }
        }

        emit(
          state.copyWith(
            listIncrease: listIncrease,
            totalIncreases: totalIncreases,
            statusIncreases: ReportsStatus.success,
          ),
        );
      },
    );
  }

  Future<void> _onGetDetailsReportLoan(
    GetDetailsReportLoan event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(statusDetails: ReportsStatus.loading));
    final result = await _loansRepository.getLoan(id: event.value);
    result.fold(
      (message) {
        emit(state.copyWith(statusDetails: ReportsStatus.error));
      },
      (data) {
        emit(
          state.copyWith(
            loanDetails: data,
            statusDetails: ReportsStatus.success,
          ),
        );
      },
    );
  }

  Future<void> _onCancelReportLoan(
    CancelReportLoan event,
    Emitter<ReportsState> emit,
  ) async {
    // Cancelar prestamo
    //await _reportsRepository.cancelLoan(id: event.id);
    emit(state.copyWith(statusCanceled: ReportsStatus.loading));
    final result = await _reportsRepository.cancelLoan(
      id: event.id,
    );
    /*  await Future.delayed(const Duration(seconds: 2));
    final result = true; */
    if (result) {
      emit(state.copyWith(statusCanceled: ReportsStatus.success));
    } else {
      emit(state.copyWith(statusCanceled: ReportsStatus.error));
    }
  }

  Future<void> _onGetDetailsReportPay(
    GetDetailsReportPay event,
    Emitter<ReportsState> emit,
  ) async {
    emit(
      state.copyWith(
        statusDetails: ReportsStatus.loading,
      ),
    );
    final result = await _loansRepository.getPayments(id: event.value);
    result.fold(
      (message) {
        emit(
          state.copyWith(
            statusDetails: ReportsStatus.error,
          ),
        );
      },
      (payment) {
        emit(
          state.copyWith(
            paymentDetails: payment,
            statusDetails: ReportsStatus.success,
          ),
        );
      },
    );
  }

  Future<void> _onAnularPrestamoLiquidado(
    AnularPrestamoLiquidado event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(statusCanceled: ReportsStatus.loading));
    final result = await _reportsRepository.cancelSettledLoan(
      id: event.codigo ?? 0,
    );
    if (result) {
      emit(state.copyWith(statusCanceled: ReportsStatus.success));
    } else {
      emit(state.copyWith(statusCanceled: ReportsStatus.error));
    }
  }
}
