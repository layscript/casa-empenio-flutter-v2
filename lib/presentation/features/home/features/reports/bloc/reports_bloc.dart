import 'dart:async';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
part 'reports_event.dart';
part 'reports_state.dart';

final _initialState = ReportsState(
  statusClosedLoans: ReportsStatus.initial,
  statusPayments: ReportsStatus.initial,
  statusIncreases: ReportsStatus.initial,
  statusLoans: ReportsStatus.initial,
  statusDetails: ReportsStatus.initial,
  statusCanceled: ReportsStatus.initial,
  statusCanceledContracts: ReportsContractsStatus.initial,
  startTimePayments: DateTime.now(),
  endTimePayments: DateTime.now(),
  startTimeContracts: DateTime.now(),
  endTimeContracts: DateTime.now(),
  listClosedLoans: const [],
  listLoans: const [],
  totalPayments: 0.0,
  partialUtilityPayment: 0.0,
  fullPaymentUtility: 0.0,
  totalClosedLoans: 0.0,
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
  message: null,
  listCategories: const [],
  selectedCategory: null,
);

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required ReportsRepository reportsRepository,
    required LoansRepository loansRepository,
    required CategoriesRepository categoriesRepository,
    required ExpensesRepository expensesRepository,
    required Preferences preferences,
    required CajaRepository cajaRepository,
  })  : _preferences = preferences,
        _reportsRepository = reportsRepository,
        _loansRepository = loansRepository,
        _categoriesRepository = categoriesRepository,
        _expensesRepository = expensesRepository,
        _cajaRepository = cajaRepository,
        super(_initialState) {
    on<GetLoadInitialDataPayments>(_onGetLoadInitialDataPayments);
    on<GetLoadInitialDataContracts>(_onGetLoadInitialDataContracts);
    on<GetDetailsReportLoan>(_onGetDetailsReportLoan);
    on<GetDetailsReportPay>(_onGetDetailsReportPay);
    on<CancelReportLoan>(_onCancelReportLoan);
    on<AnularPrestamoLiquidado>(_onAnularPrestamoLiquidado);
    on<GetCategoriesEvent>(_onGetCategoriesEvent);
    on<ChangeCategoryEvent>(_onChangeCategoryEvent);
    on<DeleteIncreaseEvent>(_onDeleteIncreaseEvent);

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
  final CategoriesRepository _categoriesRepository;
  final ExpensesRepository _expensesRepository;
  final Preferences _preferences;
  final CajaRepository _cajaRepository;

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
        sucursalId: _preferences.token?.id ?? 1,
        usuarioId: _preferences.token?.id ?? 1,
      ),
      _reportsRepository.getPaymentsByRangeDate(
        inicio: event.start ?? state.startTimePayments,
        fin: event.end ?? state.endTimePayments,
        sucursalId: _preferences.token?.id ?? 1,
        usuarioId: _preferences.token?.id ?? 1,
      ),
      _reportsRepository.getLoansByRangeDate(
        inicio: event.start ?? state.startTimePayments,
        fin: event.end ?? state.endTimePayments,
        sucursalId: _preferences.token?.id ?? 1,
        usuarioId: _preferences.token?.id ?? 1,
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
        /*  double totalLoans = 0.0;
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
        } */

        emit(state.copyWith(
          listClosedLoans: listLoans,
          totalClosedLoans: listLoans.fold<double>(
            0.0,
            (previousValue, element) {
              final monto = double.parse(element.monto ?? '0.00');
              final ganancia = double.parse(element.ganancia ?? '0.00');
              return previousValue + monto + ganancia;
            },
          ),
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
        //double gananciaGeneralPorcentaje = 0.0;
        double partialUtilityPayment = 0.0;
        double fullPaymentUtility = 0.0;

        // Filtrar pagos no cancelados
        final filterListPayments = listPayments.where((element) {
          if (element.prestamo?.estado != 'CANCELADO') {
            return true;
          } else {
            return false;
          }
        }).toList();

        if (filterListPayments.isNotEmpty) {
          for (var element in filterListPayments) {
            monto += double.parse(element.monto ?? '0.00');

            final montoPagado = double.parse(element.monto ?? '0.00');
            final montoAPagarTotal =
                double.parse(element.prestamo?.monto ?? '0.00') +
                    double.parse(element.prestamo?.ganancia ?? '0.00');

            if (montoPagado >= montoAPagarTotal) {
              // Pagó todo
              /*  gananciaGeneralPorcentaje +=
                  calcularUtilidadReportsPagoPorcentaje(
                double.parse(element.prestamo?.monto ?? '0.00'),
                double.parse(element.monto ?? '0.00'),
              ); */

              fullPaymentUtility += calcularUtilidadReportsPagoDouble(
                double.parse(element.prestamo?.monto ?? '0.00'),
                double.parse(element.monto ?? '0.00'),
              );
            } else {
              // Pago parcial
              // partialUtilityPayment += calcularUtilidadReportsPagoDoubleParcial(
              //   double.parse(element.prestamo?.ganancia ?? '0.00'),
              //   double.parse(element.monto ?? '0.00'),
              // );
            }
          }
        }

        // agrupar por prestamo
        final groupByPrestamo = groupBy<ReportsPaymentEntity, int>(
          filterListPayments,
          (obj) => obj.prestamo?.codigo ?? 0,
        );

        // Calcular utilidad por prestamo
        for (var element in groupByPrestamo.entries) {
          final gananciaPrestamo =
              element.value[0].prestamo?.ganancia ?? '0.00';

          final totalPagos = element.value.fold<double>(
            0.0,
            (previousValue, element) {
              return previousValue + double.parse(element.monto ?? '0.00');
            },
          );

          partialUtilityPayment = calcularUtilidadReportsPagoDoubleParcial(
            double.parse(gananciaPrestamo),
            totalPagos,
          );
        }

        emit(state.copyWith(
          listPayments: filterListPayments,
          totalPayments: monto,
          partialUtilityPayment: partialUtilityPayment,
          fullPaymentUtility: fullPaymentUtility,
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

  double calcularUtilidadReportsPagoPorcentaje(
    double mPrestamo,
    double mPago,
  ) {
    double utilidad;
    if (mPrestamo > mPago) {
      utilidad = mPrestamo - mPago;
    } else {
      utilidad = mPago - mPrestamo;
    }
    final utilidadPorcentaje = utilidad / mPago;
    return utilidadPorcentaje;
  }

  double calcularUtilidadReportsPagoDouble(
    double mPrestamo,
    double mPago,
  ) {
    double utilidad;
    if (mPrestamo > mPago) {
      utilidad = mPrestamo - mPago;
    } else {
      utilidad = mPago - mPrestamo;
    }
    final utilidadPorcentaje = utilidad / mPago;
    final utilidadDouble = utilidadPorcentaje * mPago;
    return utilidadDouble;
  }

  double calcularUtilidadReportsPagoDoubleParcial(
    double gPrestamo,
    double mPago,
  ) {
    if (mPago > gPrestamo) {
      return gPrestamo;
    }
    return gPrestamo - mPago;
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
        statusClosedLoans: ReportsStatus.initial,
        statusDetails: ReportsStatus.initial,
        statusPayments: ReportsStatus.initial,
        //statusCanceledContracts: ReportsContractsStatus.initial,
        startTimeContracts: event.start,
        endTimeContracts: event.end,
      ),
    );

    final result = await Future.wait([
      _reportsRepository.getLoansByRangeDate(
        inicio: event.start ?? state.startTimeContracts,
        fin: event.end ?? state.endTimeContracts,
        sucursalId: _preferences.token?.id ?? 1,
        usuarioId: _preferences.token?.id ?? 1,
      ),
      _reportsRepository.getIncreasesByRangeDate(
        inicio: event.start ?? state.startTimeContracts,
        fin: event.end ?? state.endTimeContracts,
        sucursal: _preferences.token?.sucursal?.id ?? 1,
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
            selectedCategory: null,
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
    final result = await _loansRepository.getLoan(
      id: event.value,
      userId: null,
    );
    result.fold(
      (message) {
        emit(
          state.copyWith(
            statusDetails: ReportsStatus.error,
            message: message,
          ),
        );
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
    emit(
      state.copyWith(
        statusCanceledContracts: ReportsContractsStatus.loading,
      ),
    );

    try {
      final getCajaOfTheDay = await _cajaRepository.getCajaOfTheDay();
      await getCajaOfTheDay.fold(
        (error) async {
          emit(
            state.copyWith(
              statusCanceledContracts: ReportsContractsStatus.error,
              message: error,
            ),
          );
        },
        (caja) async {
          if (caja?.id == event.idCaja) {
            final response = await _loansRepository.deleteLoan(
              idLoan: event.loanId,
              userId: event.userId,
            );

            response.fold(
              (err) => emit(
                state.copyWith(
                  statusCanceledContracts: ReportsContractsStatus.error,
                  message: err,
                ),
              ),
              (result) {
                if (result) {
                  emit(
                    state.copyWith(
                      statusCanceledContracts: ReportsContractsStatus.success,
                    ),
                  );

                  add(
                    const GetLoadInitialDataContracts(
                      start: null,
                      end: null,
                    ),
                  );
                } else {
                  emit(
                    state.copyWith(
                      statusCanceledContracts: ReportsContractsStatus.error,
                    ),
                  );
                }
              },
            );
          } else {
            emit(
              state.copyWith(
                statusCanceledContracts: ReportsContractsStatus.error,
                message:
                    'No se puede eliminar porque no pertenece a la caja actual',
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(
          statusCanceledContracts: ReportsContractsStatus.error));
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

  // Se cancela el prestamo cerrado

  Future<void> _onAnularPrestamoLiquidado(
    AnularPrestamoLiquidado event,
    Emitter<ReportsState> emit,
  ) async {
    // TODO:: Revisar bien

    //emit(state.copyWith(statusCanceled: ReportsStatus.loading));
    final result = await _reportsRepository.cancelSettledLoan(
      id: event.codigo ?? 0,
    );
    if (result) {
      emit(state.copyWith(statusCanceled: ReportsStatus.success));
    } else {
      emit(state.copyWith(statusCanceled: ReportsStatus.error));
    }
  }

  Future<void> _onGetCategoriesEvent(
    GetCategoriesEvent event,
    Emitter<ReportsState> emit,
  ) async {
    //emit(state.copyWith(statusCanceled: ReportsStatus.loading));
    final result = await _categoriesRepository.getCategories();
    result.fold(
      (message) {},
      (categories) {
        emit(
          state.copyWith(
            listCategories: categories,
          ),
        );
      },
    );
  }

  Future<void> _onChangeCategoryEvent(
    ChangeCategoryEvent event,
    Emitter<ReportsState> emit,
  ) async {
    /*  final newListIncreate = state.listIncrease.where((element) {
      if (element.prestamo?.bienesGarantia == null) return false;
      for (var e in element.prestamo!.bienesGarantia!) {
        if (e.categoria != null) {
          if (e.categoria == event.category?.descripcion) {
            return true;
          }
        }
      }
      return false;
    }).toList(); */

    final newListLoans = state.listLoans.where((element) {
      if (element.bienesGarantia == null) return false;
      for (var e in element.bienesGarantia!) {
        if (e.categoria != null) {
          if (e.categoria == event.category?.descripcion) {
            return true;
          }
        }
      }
      return false;
    }).toList();

    emit(
      state.copyWith(
        selectedCategory: event.category,
        listLoans: newListLoans,
        //listIncrease: newListIncreate,
      ),
    );
  }

  Future<void> _onDeleteIncreaseEvent(
    DeleteIncreaseEvent event,
    Emitter<ReportsState> emit,
  ) async {
    // TODO:: Revisar bien
    //emit(state.copyWith(statusIncreases: ReportsStatus.loading));
    await _reportsRepository.deleteIncrease(
      id: event.id,
      idUser: event.userId,
    );

    add(GetLoadInitialDataContracts(
      start: state.startTimeContracts,
      end: state.endTimeContracts,
    ));
  }
}
