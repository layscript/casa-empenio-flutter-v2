import 'dart:async';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

part 'loans_event.dart';
part 'loans_state.dart';

class LoansBloc extends Bloc<LoansEvent, LoansState> {
  LoansBloc({
    required CustomerRepository customerRepository,
    required LoansRepository loansRepository,
    required CajaRepository cajaRepository,
    required SolicitudRepository solicitudRepository,
    required Preferences preferences,
    required AnexoRepository anexoRepository,
    required CategoriesRepository categoriesRepository,
  })  : _customerRepository = customerRepository,
        _loansRepository = loansRepository,
        _cajaRepository = cajaRepository,
        _solicitudRepository = solicitudRepository,
        _anexoRepository = anexoRepository,
        _preferences = preferences,
        _categoriesRepository = categoriesRepository,
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
    on<UpdateAllLoan>(_onUpdateAllLoan);

    on<DeleteLoanById>(_onDeleteLoanById);
    on<AnularLoanId>(_onAnularLoanId);
    on<DeletePaymentLoanId>(_onDeletePaymentLoanId);
    on<UpdateStatusLoanById>(_onUpdateStatusLoanById);

    on<CreateSolicitud>(_onCreateSolicitud);
    on<SaveAnexoLoan>(_onSaveAnexoLoan);
    on<GetAnexosLoan>(_onGetAnexosLoan);
  }

  final CustomerRepository _customerRepository;
  final LoansRepository _loansRepository;
  final CajaRepository _cajaRepository;
  final SolicitudRepository _solicitudRepository;
  final Preferences _preferences;
  final AnexoRepository _anexoRepository;
  final CategoriesRepository _categoriesRepository;

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
    final preferences = _preferences.token;
    final result = await _customerRepository.getCustomerByDni(
        dni: event.value,
        userId: preferences?.id ?? 0,
        sucursal: preferences?.sucursal?.id ?? 1);
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
        searchText: event.criterio,
        categoriaText: event.categoria,
      ),
    );
    final preferences = _preferences.token;
    final result = await _loansRepository.getLoans(
      criterio: event.criterio ?? state.searchText,
      userId: preferences?.id ?? 0,
      sucursal: preferences?.sucursal?.id ?? 1,
      categoria: event.categoria ?? state.categoriaText,
      offset: event.offset,
    );
    result.fold(
      (message) => emit(_errorState(message)),
      (loans) {
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

    final preferences = _preferences.token;
    final result = await _loansRepository.getLoan(
      id: event.value,
      userId: preferences?.id ?? 0,
    );
    result.fold((message) {
      emit(
        _errorState(message),
      );
    }, (data) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.loaded,
          loanDetails: data,
        ),
      );
    });
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
          // En caso de error, cambiar el estado a loaded pero con un mensaje de error
          // Esto permite que la UI siga mostrando el formulario sin quedarse bloqueada
          emit(
            state.copyWith(
              loansStatus: LoansStatus.loaded,
              error: message,
              customerSunat: null, // Asegurarse de que no haya datos antiguos
            ),
          );
          
          // Mostrar el mensaje de error en la consola para depuración
          log('Error al buscar DNI: $message');
        },
        (customerSunat) {
          emit(
            state.copyWith(
              loansStatus: LoansStatus.loaded,
              customerSunat: customerSunat,
              error: null, // Limpiar cualquier error anterior
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
    if (state.loansStatus == LoansStatus.loading) return;
    emit(_loadingState);

    final urlImg = await savePhotoPayment(event.photos);
    final monto = double.tryParse(event.monto);
    final montoRestante = double.tryParse(event.montoRestante);

    if (monto == null || monto <= 0 || montoRestante == null) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.paymentError,
          error: 'Ingrese un monto válido mayor que cero.',
        ),
      );
      return;
    }

    if ((monto - montoRestante).abs() > 0.009) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.paymentError,
          error:
              'El monto ingresado debe coincidir exactamente con el importe pendiente: S/ ${montoRestante.toStringAsFixed(2)}.',
        ),
      );
      return;
    }

    final resultPayment = await _loansRepository.savePayment(
      codigo: event.idPrestamo,
      monto: monto,
      userId: event.userId,
      url: urlImg,
      efectivo: event.efectivo,
      cajaId: state.cajaId,
    );

    resultPayment.fold(
      (message) => emit(
        state.copyWith(
          loansStatus: LoansStatus.paymentError,
          error: message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          loansStatus: LoansStatus.paymentSuccess,
          error: 'El pago se registró correctamente.',
        ),
      ),
    );
  }

  Future<void> _onSaveSettlementLoan(
    SaveSettlementLoan event,
    Emitter<LoansState> emit,
  ) async {
    if (state.loansStatus == LoansStatus.loading) return;
    emit(_loadingState);
    final urlImg = await savePhotoPayment(event.photos);
    final monto = double.tryParse(event.monto);
    if (monto == null || monto <= 0) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.settlementError,
          error: 'El monto de liquidación debe ser mayor que cero.',
        ),
      );
      return;
    }

    final resultPayment = await _loansRepository.savePayment(
      codigo: event.idPrestamo,
      monto: monto,
      userId: event.userId,
      url: urlImg,
      efectivo: event.efectivo,
      cajaId: state.cajaId,
      isLiquidacion: true,
    );

    resultPayment.fold(
      (message) => emit(
        state.copyWith(
          loansStatus: LoansStatus.settlementError,
          error: message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          loansStatus: LoansStatus.settlementSuccess,
          error: 'La liquidación se registró correctamente y la operación fue cerrada.',
        ),
      ),
    );
  }

  Future<void> _onAddAmountLoan(
    AddAmountLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(
      state.copyWith(
        loansStatus: LoansStatus.addAmountLoading,
      ),
    );

    final imgUrl = await savePhotoIncreases(event.photos);
    final result = await _loansRepository.addAmountLoan(
      codigo: event.idPrestamo,
      monto: event.monto,
      observaciones: event.obs,
      userId: event.userId,
      url: imgUrl,
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
      userId: event.userId,
    );

    result.fold(
      (message) => emit(
        state.copyWith(
          loansStatus: LoansStatus.electronicTicketError,
          error: message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          loansStatus: LoansStatus.electronicTicketSuccess,
          error: 'La boleta se generó correctamente.',
        ),
      ),
    );
  }

  Future<void> _onGetCashStatus(
    GetCashStatus event,
    Emitter<LoansState> emit,
  ) async {
    try {
      // Emitir estado de carga
      emit(state.copyWith(loansStatus: LoansStatus.loading));

      // Llamar a la API para obtener el estado de caja del día
      final getCajaOftheDayResult = await _cajaRepository.getCajaOfTheDay(
        sucursalId: _preferences.token?.sucursal?.id ?? 1,
      );

      // Variables para almacenar el resultado de la primera llamada
      int? cajaId;
      var openBox = true;

      // Procesar el resultado de la llamada de caja del día
      await getCajaOftheDayResult.fold(
        // Manejo de error en la llamada de caja del día
        (error) async {
          emit(
            state.copyWith(
              openBox: true,
              loansStatus: LoansStatus.loaded,
            ),
          );
        },
        // Manejo de éxito en la llamada de caja del día
        (box) async {
          cajaId = box?.id;
          openBox = box == null;

          // Llamar a la API para obtener las categorías solo si la primera llamada fue exitosa
          final getCategoriesResult =
              await _categoriesRepository.getCategories();

          // Procesar el resultado de la llamada de categorías
          getCategoriesResult.fold(
            // Manejo de error en la llamada de categorías
            (error) async {
              emit(
                state.copyWith(
                  openBox: true,
                  loansStatus: LoansStatus.loaded,
                ),
              );
            },
            // Manejo de éxito en la llamada de categorías
            (categories) async {
              emit(
                state.copyWith(
                  openBox: openBox,
                  loansStatus: LoansStatus.loaded,
                  cajaId: cajaId,
                  listCategories: categories,
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      // Manejo de excepción
      print('Error: $e');
      emit(
        state.copyWith(
          loansStatus: LoansStatus.error,
        ),
      );
    }
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

    final preferences = _preferences.token;
    final result = await _customerRepository.getCustomerByDni(
        dni: event.value,
        userId: preferences?.id ?? 0,
        sucursal: preferences?.sucursal?.id ?? 1);

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

  Future<void> _onUpdateAllLoan(
    UpdateAllLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(state.copyWith(loansRenewStatus: LoansStatus.updateLoansLoading));

    // Renovar
    if (event.isNuevo) {
      final result = await _loansRepository.saveLoan(
        cajaId: state.cajaId,
        plazoDias: event.plazoDias,
        interes: event.interes,
        fechaPago: event.fechaPago,
        monto: event.monto,
        observaciones: event.observaciones,
        cliente: event.cliente,
        aval: event.aval.dni == null ? null : event.aval,
        bienes: event.bienes,
        usuarioId: event.userId,
        //renew: true,
        renew: event.isRenew ?? false,
        // TODO:: ID SUCURSSCAL
        sucursalId: _preferences.token?.sucursal?.id ?? 1,
      );
      result.fold(
        (error) => emit(
          state.copyWith(loansRenewStatus: LoansStatus.updateLoansError),
        ),
        (contrato) => emit(
          state.copyWith(loansRenewStatus: LoansStatus.updateLoansSuccess),
        ),
      );
    } else {
      final result = await _loansRepository.updateLoan(
        plazoDias: event.plazoDias,
        interes: event.interes,
        fechaPago: event.fechaPago,
        monto: event.monto,
        observaciones: event.observaciones,
        cliente: event.cliente,
        aval: event.aval.dni == null ? null : event.aval,
        bienes: event.bienes,
        usuarioId: event.userId,
        idLoan: event.codigo,
        cajaId: state.cajaId ?? 1,
        sucursalId: _preferences.token?.sucursal?.id ?? 1,
      );
      result.fold(
        (error) => emit(
          state.copyWith(loansRenewStatus: LoansStatus.updateLoansError),
        ),
        (contrato) => emit(
          state.copyWith(loansRenewStatus: LoansStatus.updateLoansSuccess),
        ),
      );
    }
  }

  Future<void> _onDeleteLoanById(
    DeleteLoanById event,
    Emitter<LoansState> emit,
  ) async {
    emit(state.copyWith(loansStatus: LoansStatus.deleteLoanLoading));

    final getCajaOfTheDay = await _cajaRepository.getCajaOfTheDay(
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
    );

    await getCajaOfTheDay.fold(
      (error) async => emit(
        state.copyWith(loansStatus: LoansStatus.deleteLoanError),
      ),
      (caja) async {
        if (caja?.id == event.idCaja) {
          final response = await _loansRepository.deleteLoan(
            idLoan: event.idLoan,
            userId: event.userId,
          );

          await response.fold(
            (error) async => emit(
              state.copyWith(
                loansStatus: LoansStatus.deleteLoanError,
                error: error,
              ),
            ),
            (result) async {
              if (result) {
                emit(
                    state.copyWith(loansStatus: LoansStatus.deleteLoanSuccess));
              } else {
                emit(state.copyWith(loansStatus: LoansStatus.deleteLoanError));
              }
            },
          );
        } else {
          emit(
            state.copyWith(
              loansStatus: LoansStatus.deleteLoanError,
              error:
                  'No se puede eliminar porque no pertenece a la caja actual',
            ),
          );
        }
      },
    );

    /*   */
  }

  Future<void> _onAnularLoanId(
    AnularLoanId event,
    Emitter<LoansState> emit,
  ) async {
    emit(state.copyWith(loansStatus: LoansStatus.deleteLoanLoading));
    final result = await _loansRepository.anularLoan(
      idLoan: event.idLoan,
      userId: event.userId,
    );
    if (result) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.deleteLoanSuccess,
          error: 'Anulado correctamente',
        ),
      );
    } else {
      emit(
        state.copyWith(loansStatus: LoansStatus.deleteLoanError),
      );
    }
  }

  Future<void> _onDeletePaymentLoanId(
    DeletePaymentLoanId event,
    Emitter<LoansState> emit,
  ) async {
    emit(state.copyWith(loansStatus: LoansStatus.deleteLoanLoading));
    try {
      final getCajaOfTheDay = await _cajaRepository.getCajaOfTheDay(
        sucursalId: _preferences.token?.sucursal?.id ?? 1,
      );

      await getCajaOfTheDay.fold(
        (error) async => emit(
          state.copyWith(
            loansStatus: LoansStatus.deleteLoanError,
            error: error,
          ),
        ),
        (caja) async {
          if (caja?.id == event.idCaja) {
            final result = await _loansRepository.deletePayment(
              userId: int.parse(event.userId),
              id: event.paymentId,
            );

            result.fold(
              (error) => emit(
                state.copyWith(
                  loansStatus: LoansStatus.deleteLoanError,
                  error: error,
                ),
              ),
              (success) => emit(
                state.copyWith(
                  loansStatus: LoansStatus.deleteLoanSuccess,
                ),
              ),
            );
          } else {
            emit(
              state.copyWith(
                loansStatus: LoansStatus.deleteLoanError,
                error:
                    'No se puede eliminar porque no pertenece a la caja actual',
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          loansStatus: LoansStatus.deleteLoanSuccess,
        ),
      );
    }
  }

  Future<void> _onUpdateStatusLoanById(
    UpdateStatusLoanById event,
    Emitter<LoansState> emit,
  ) async {
    emit(state.copyWith(loansStatus: LoansStatus.updateStatusLoanLoading));
    final result = await _loansRepository.updateStatusLoan(
      idLoan: event.idLoan,
      value: event.value,
    );
    if (result) {
      emit(state.copyWith(loansStatus: LoansStatus.updateStatusLoanSuccess));
    } else {
      emit(state.copyWith(loansStatus: LoansStatus.updateStatusLoanError));
    }
  }

  Future<void> _onCreateSolicitud(
    CreateSolicitud event,
    Emitter<LoansState> emit,
  ) async {
    emit(state.copyWith(solicitudStatus: LoansStatus.loading));

    final result = await _solicitudRepository.createSolicitud(
      prestamoId: event.prestamoId,
      estado: event.estado,
      usuarioId: event.usuarioId,
    );

    result.fold(
      (err) {
        emit(
          state.copyWith(
            error: err,
            solicitudStatus: LoansStatus.error,
          ),
        );
      },
      (success) {
        emit(state.copyWith(
          solicitudStatus: LoansStatus.loaded,
        ));
      },
    );
  }

  Future<void> _onSaveAnexoLoan(
    SaveAnexoLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(state.copyWith(anexosLoanStatus: AnexosLoanStatus.loading));
    List<String> images = [];
    if (event.imagenes != null) {
      for (var img in event.imagenes!) {
        final url = await _anexoRepository.createImage(path: img.path);
        url.fold(
          (error) => emit(
            state.copyWith(
              anexosLoanStatus: AnexosLoanStatus.error,
              error: error,
            ),
          ),
          (success) => images.add(success),
        );
      }

      if (images.isNotEmpty) {
        final result = await _anexoRepository.createAnexo(
          description: event.description,
          prestamoId: event.prestamoId,
          url: images.map((e) {
            return {'url': e};
          }).toList(),
        );

        result.fold(
          (error) => emit(
            state.copyWith(
              anexosLoanStatus: AnexosLoanStatus.error,
              error: error,
            ),
          ),
          (success) => emit(
            state.copyWith(
              anexosLoanStatus: AnexosLoanStatus.success,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onGetAnexosLoan(
    GetAnexosLoan event,
    Emitter<LoansState> emit,
  ) async {
    emit(
      state.copyWith(
        listAnexosStatus: AnexosLoanStatus.loading,
      ),
    );
    try {
      final result = await _anexoRepository.getAnexoByPrestamo(
        prestamoId: event.idPrestamo,
      );
      result.fold((error) {
        emit(
          state.copyWith(
            listAnexos: [],
            listAnexosStatus: AnexosLoanStatus.error,
            error: error,
          ),
        );
      }, (data) {
        emit(
          state.copyWith(
            listAnexos: data,
            listAnexosStatus: AnexosLoanStatus.success,
          ),
        );
      });
    } catch (e) {
      emit(
        state.copyWith(
          listAnexos: [],
          error: e.toString(),
          listAnexosStatus: AnexosLoanStatus.error,
        ),
      );
    }
  }

  Future<String> savePhotoPayment(List<XFile>? photos) async {
    final result = await _loansRepository.createImagePagos(
      path: photos?.first.path ?? '',
    );
    return result.fold(
      (err) => '',
      (success) => success,
    );
  }

  Future<String> savePhotoIncreases(List<XFile>? photos) async {
    final result = await _loansRepository.createImageAumentos(
      path: photos?.first.path ?? '',
    );
    return result.fold(
      (err) => '',
      (success) => success,
    );
  }
}
