import 'dart:async';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'loans_step_event.dart';
part 'loans_step_state.dart';

class LoansStepBloc extends Bloc<LoansStepEvent, LoansStepState> {
  LoansStepBloc({
    required LoansRepository loansRepository,
    required InterestsRepository interestsRepository,
    required CategoriesRepository categoriesRepository,
    required Preferences preferences,
    required SentryClient sentry,
  })  : _loansRepository = loansRepository,
        _interestsRepository = interestsRepository,
        _preferences = preferences,
        _categoriesRepository = categoriesRepository,
        _sentry = sentry,
        super(const LoansStepState()) {
    // NEWWWW

    on<SaveFirstStepOne>(_onSaveFirstStepOne);
    on<SaveSecondStepOne>(_onSaveSecondStepOne);
    on<SaveThirdStepOne>(_onSaveThirdStepOne);

    //
    on<GetLastCodeLoans>(_onGetLastCodeLoans);

    on<ChangeIndexLoans>(_onChangeIndexLoans);
    //
    on<ChangeHasClientAval>(_onChangeHasClientAval);

    on<ChangeDocumentClient>(_onChangeDocumentClient);
    on<ChangeFullNamesClient>(_onChangeFullNamesClient);
    on<ChangeFullLastNamesClient>(_onChangeFullLastNamesClient);
    on<ChangePhoneClient>(_onChangePhoneClient);
    on<ChangeEmailClient>(_onChangeEmailClient);
    on<ChangeHomeClient>(_onChangeHomeClient);

    on<ChangeDocumentAval>(_onChangeDocumentAval);
    on<ChangeFullNamesAval>(_onChangeFullNamesAval);
    on<ChangeFullLastNamesAval>(_onChangeFullLastNamesAval);
    on<ChangePhoneAval>(_onChangePhoneAval);
    on<ChangeEmailAval>(_onChangeEmailAval);
    on<ChangeHomeAval>(_onChangeHomeAval);
    //
    on<ChangeCodeLoans>(_onChangeCodeLoans);
    on<ChangeStartDate>(_onChangeStartDate);
    on<ChangeAmount>(_onChangeAmount);
    on<ChangeDeadLines>(_onChangeDeadLines);
    on<ChangeInterestRate>(_onChangeInterestRate);
    on<ChangePaymentRate>(_onChangePaymentRate);
    on<ChangeObservations>(_onChangeObservations);
    on<ChangeDescription>(_onChangeDescription);
    on<ChangeBrand>(_onChangeBrand);
    on<ChangeModel>(_onChangeModel);
    on<ChangeColor>(_onChangeColor);
    on<ChangeStatus>(_onChangeStatus);
    on<ChangeSerie>(_onChangeSerie);
    on<ChangeWarrantyObservations>(_onChangeWarrantyObservations);
    on<ChangePrice>(_onChangePrice);
    on<AddListWarranty>(_onAddListWarranty);
    on<EditListWarranty>(_onEditListWarranty);
    on<DeleteListWarranty>(_onDeleteListWarranty);
    on<ChangeStatusAddListWarranty>(_onChangeStatusAddListWarranty);
    on<ChangeStatusEditListWarranty>(_onChangeStatusEditListWarranty);
    on<UploadImagesWarranty>(_onUploadImagesWarranty);
    on<SaveAllLoan>(_onSaveAllLoan);
  }

  final LoansRepository _loansRepository;
  final InterestsRepository _interestsRepository;
  final CategoriesRepository _categoriesRepository;
  final Preferences _preferences;
  final SentryClient _sentry;

  void _onChangeIndexLoans(
    ChangeIndexLoans event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(index: event.index));
  }

  // one step - client
  Future<void> _onChangeDocumentClient(
    ChangeDocumentClient event,
    Emitter<LoansStepState> emit,
  ) async {
    /* await _preferences.setDocument(event.value); */
    emit(state.copyWith(documentClient: event.value));
  }

  void _onChangeFullNamesClient(
    ChangeFullNamesClient event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(fullNamesClient: event.value));
  }

  void _onChangeFullLastNamesClient(
    ChangeFullLastNamesClient event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(fullLastNamesClient: event.value));
  }

  void _onChangePhoneClient(
    ChangePhoneClient event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(phoneClient: event.value));
  }

  void _onChangeEmailClient(
    ChangeEmailClient event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(emailClient: event.value));
  }

  void _onChangeHomeClient(
    ChangeHomeClient event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(homeClient: event.value));
  }

  // one step - aval
  void _onChangeDocumentAval(
    ChangeDocumentAval event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(documentAval: event.value));
  }

  void _onChangeFullNamesAval(
    ChangeFullNamesAval event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(fullNamesAval: event.value));
  }

  void _onChangeFullLastNamesAval(
    ChangeFullLastNamesAval event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(fullLastNamesAval: event.value));
  }

  void _onChangePhoneAval(
    ChangePhoneAval event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(phoneAval: event.value));
  }

  void _onChangeEmailAval(
    ChangeEmailAval event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(emailAval: event.value));
  }

  void _onChangeHomeAval(
    ChangeHomeAval event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(homeAval: event.value));
  }

//
  void _onChangeCodeLoans(
    ChangeCodeLoans event,
    Emitter<LoansStepState> emit,
  ) {
    //emit(state.copyWith(codeLoans: event.value));
  }

  void _onChangeStartDate(
    ChangeStartDate event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(startDate: event.value));
  }

  void _onChangeAmount(
    ChangeAmount event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(amount: event.value));
  }

  void _onChangeDeadLines(
    ChangeDeadLines event,
    Emitter<LoansStepState> emit,
  ) {
    final now = DateTime.now();
    final datePay = now.add(
      Duration(
        days: int.parse(event.value == '' ? '0' : event.value) - 1,
      ),
    );

    final datePayFormatt = DateFormat('dd/MM/yyyy').format(
      datePay,
    );

    emit(
      state.copyWith(
        paymentDateWithoutFormatt: datePay,
        paymentDate: datePayFormatt,
        deadlines: event.value,
      ),
    );
  }

  void _onChangeInterestRate(
    ChangeInterestRate event,
    Emitter<LoansStepState> emit,
  ) {
    final monto = double.tryParse(state.amount ?? '0.00');
    final porcentaje = double.tryParse(event.value?.intereses ?? '0.00');
    if (monto != null && porcentaje != null) {
      final interes = (monto * porcentaje) / 100;
      final total = monto + interes;

      final oCcy = NumberFormat("#,##0.00", "en_US");
      emit(
        state.copyWith(
          interestRate: event.value,
          totalToPay: oCcy.format(total),
          totalProfit: oCcy.format(interes),
        ),
      );
    }
  }

  void _onChangePaymentRate(
    ChangePaymentRate event,
    Emitter<LoansStepState> emit,
  ) {
    //emit(state.copyWith(paymentDate: event.value));
  }

  void _onChangeObservations(
    ChangeObservations event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(observations: event.value));
  }

  void _onChangeDescription(
    ChangeDescription event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        description: event.value,
        idWarranty: state.idWarranty,
        status: state.status,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onChangeBrand(
    ChangeBrand event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        brand: event.value,
        idWarranty: state.idWarranty,
        status: state.status,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onChangeModel(
    ChangeModel event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        model: event.value,
        idWarranty: state.idWarranty,
        status: state.status,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onChangeColor(
    ChangeColor event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        color: event.value,
        idWarranty: state.idWarranty,
        status: state.status,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onChangeStatus(
    ChangeStatus event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        status: event.value,
        idWarranty: state.idWarranty,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onChangeSerie(
    ChangeSerie event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        serie: event.value,
        idWarranty: state.idWarranty,
        status: state.status,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onChangeWarrantyObservations(
    ChangeWarrantyObservations event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        warrantyObservations: event.value,
        idWarranty: state.idWarranty,
        status: state.status,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onChangePrice(
    ChangePrice event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        price: event.value,
        idWarranty: state.idWarranty,
        status: state.status,
        photoWarranty: state.photoWarranty,
      ),
    );
  }

  void _onAddListWarranty(
    AddListWarranty event,
    Emitter<LoansStepState> emit,
  ) async {
    List<WarrantyState>? newList;
    if (state.listWarranty != null) {
      newList = [...state.listWarranty!, event.value];
    } else {
      newList = [event.value];
    }

    final newStateLocal = event.localState.copyWith(
      warrantyPreferences: newList,
    );
    await _preferences.setLoansPreferences(newStateLocal);

    emit(
      state.copyWith(
        listWarranty: newList,
        addListWarranty: false,
        idWarranty: null,
      ),
    );
  }

  Future<void> _onEditListWarranty(
    EditListWarranty event,
    Emitter<LoansStepState> emit,
  ) async {
    final updateWarranty = event.value;

    final listWarrantyLocal =
        _preferences.getLoansPreferences?.warrantyPreferences;

    List<WarrantyState> updatedList;
    int index;
    if (listWarrantyLocal != null) {
      updatedList = List<WarrantyState>.from(listWarrantyLocal);
      index = updatedList.indexWhere((e) => e.id == updateWarranty.id);
    } else {
      updatedList = List<WarrantyState>.from(state.listWarranty!);
      index = updatedList.indexWhere((e) => e.id == updateWarranty.id);
    }

    if (index != -1) {
      updatedList[index] = updateWarranty;
      final response = await _preferences.setLoansPreferences(
        event.localState.copyWith(warrantyPreferences: updatedList),
      );

      if (response) {
        emit(
          state.copyWith(
            listWarranty: updatedList,
            idWarranty: null,
            addListWarranty: false,
          ),
        );
      }
    }

    /* if (state.listWarranty != null) {
      final updatedList = List<WarrantyState>.from(state.listWarranty!);
      final index = updatedList.indexWhere((e) => e.id == updateWarranty.id);

      if (index != -1) {
        updatedList[index] = updateWarranty;
        //emit(LoansStepState(listWarranty: updatedList));
        emit(
          state.copyWith(
            listWarranty: updatedList,
            idWarranty: null,
            addListWarranty: false,
          ),
        );
      }
    } */
  }

  void _onDeleteListWarranty(
    DeleteListWarranty event,
    Emitter<LoansStepState> emit,
  ) async {
    final deleteWarranty = event.value;

    final listWarrantyLocal =
        _preferences.getLoansPreferences?.warrantyPreferences;

    List<WarrantyState>? newList;

    if (listWarrantyLocal != null) {
      newList =
          listWarrantyLocal.where((e) => e.id != deleteWarranty.id).toList();
    } else {
      newList =
          state.listWarranty?.where((e) => e.id != deleteWarranty.id).toList();
    }

    final response = await _preferences.setLoansPreferences(
      event.localState.copyWith(warrantyPreferences: newList),
    );

    if (response) {
      emit(
        state.copyWith(
          listWarranty: newList,
          addListWarranty: newList != null && newList.isEmpty,
          model: '',
          serie: '',
          brand: '',
          price: '',
          warrantyObservations: '',
          color: '',
          status: null,
          idWarranty: null,
          photoWarranty: null,
        ),
      );
    }
  }

  void _onChangeStatusAddListWarranty(
    ChangeStatusAddListWarranty event,
    Emitter<LoansStepState> emit,
  ) {
    /*  emit(
      state.copyWith(
        addListWarranty: event.value,
        description: '',
        model: '',
        serie: '',
        brand: '',
        price: '',
        warrantyObservations: '',
        color: '',
        status: null,
        idWarranty: null,
        photoWarranty: null,
      ),
    ); */

    emit(
      const LoansStepState().copyWith(
        loansStepStatus: state.loansStepStatus,
        message: state.message,
        index: state.index,
        isAval: state.isAval,
        documentClient: state.documentClient,
        fullNamesClient: state.fullNamesClient,
        fullLastNamesClient: state.fullLastNamesClient,
        emailClient: state.emailClient,
        homeClient: state.homeClient,
        phoneClient: state.phoneClient,
        photosClient: state.photosClient,
        documentAval: state.documentAval,
        fullNamesAval: state.fullNamesAval,
        fullLastNamesAval: state.fullLastNamesAval,
        emailAval: state.emailAval,
        homeAval: state.homeAval,
        phoneAval: state.phoneAval,
        photosAval: state.photosAval,
        amount: state.amount,
        codeLoans: state.codeLoans,
        deadlines: state.deadlines,
        listInterests: state.listInterests,
        interestRate: state.interestRate,
        observations: state.observations,
        paymentDate: state.paymentDate,
        paymentDateWithoutFormatt: state.paymentDateWithoutFormatt,
        startDate: state.startDate,
        listWarranty: state.listWarranty,
        addListWarranty: event.value,
        idWarranty: state.idWarranty,
        totalToPay: state.totalToPay,
        totalProfit: state.totalProfit,
        listCategories: state.listCategories,
      ),
    );
  }

  void _onChangeStatusEditListWarranty(
    ChangeStatusEditListWarranty event,
    Emitter<LoansStepState> emit,
  ) {
    final listWarrantyLocal =
        _preferences.getLoansPreferences?.warrantyPreferences;
    WarrantyState filterData;
    if (listWarrantyLocal != null) {
      filterData = listWarrantyLocal.firstWhere(
        (e) => e.id == event.id,
      );
    } else {
      filterData = state.listWarranty!.firstWhere(
        (e) => e.id == event.id,
      );
    }

    emit(
      state.copyWith(
        addListWarranty: event.value,
        description: filterData.description,
        placa: filterData.placa,
        categories: filterData.category,
        idWarranty: event.id,
        brand: filterData.brand,
        model: filterData.model,
        color: filterData.color,
        status: filterData.status,
        serie: filterData.serie,
        warrantyObservations: filterData.warrantyObservations,
        price: filterData.price,
        photoWarranty: filterData.photoWarranty,
      ),
    );
  }

  void _onChangeHasClientAval(
    ChangeHasClientAval event,
    Emitter<LoansStepState> emit,
  ) {
    if (event.value == false) {
      emit(
        state.copyWith(
          isAval: event.value,
          homeAval: '',
          emailAval: '',
          phoneAval: '',
          documentAval: '',
          fullNamesAval: '',
          fullLastNamesAval: '',
        ),
      );
    } else {
      emit(state.copyWith(isAval: event.value));
    }
  }

  Future<void> _onGetLastCodeLoans(
    GetLastCodeLoans event,
    Emitter<LoansStepState> emit,
  ) async {
    emit(state.copyWith(loansStepStatus: LoansStepStatus.loading));
    final result = await Future.wait([
      _loansRepository.getLastCode(),
      _interestsRepository.getInterest(),
      _categoriesRepository.getCategories(),
    ]);

    final formattedDate = _onGetToday();
    final resultLastCode = result[0] as Either<String, int>;
    final resultListInterest =
        result[1] as Either<String, List<InterestsEntity>>;

    final resultListCategories =
        result[2] as Either<String, List<CategoriesEntity>>;

    resultLastCode.fold(
      (error) => emit(
        state.copyWith(
          loansStepStatus: LoansStepStatus.error,
          message: error,
        ),
      ),
      (lastCode) => emit(
        state.copyWith(
          loansStepStatus: LoansStepStatus.loaded,
          codeLoans: (lastCode + 1).toString().padLeft(6, '0'),
          startDate: formattedDate,
        ),
      ),
    );

    resultListInterest.fold(
      (error) => emit(
        state.copyWith(
          loansStepStatus: LoansStepStatus.error,
          message: error,
        ),
      ),
      (listInteres) => emit(
        state.copyWith(
          loansStepStatus: LoansStepStatus.loaded,
          listInterests: listInteres,
          startDate: formattedDate,
        ),
      ),
    );

    resultListCategories.fold(
      (error) => emit(
        state.copyWith(
          loansStepStatus: LoansStepStatus.error,
          message: error,
        ),
      ),
      (listCategories) => emit(
        state.copyWith(
          loansStepStatus: LoansStepStatus.loaded,
          listCategories: listCategories,
          startDate: formattedDate,
        ),
      ),
    );
  }

  String _onGetToday() {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(now);
    return formattedDate;
  }

  Future<void> _onUploadImagesWarranty(
    UploadImagesWarranty event,
    Emitter<LoansStepState> emit,
  ) async {
    /* final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    emit(
      state.copyWith(
        photoWarranty: photo,
        idWarranty: state.idWarranty,
        status: state.status,
      ),
    ); */
  }

  Future<void> _onSaveAllLoan(
    SaveAllLoan event,
    Emitter<LoansStepState> emit,
  ) async {
    /*  emit(state.copyWith(loansStepStatusSaved: LoansStepStatus.loading));
    await Future.delayed(const Duration(seconds: 3));
    emit(state.copyWith(loansStepStatusSaved: LoansStepStatus.success)); */

    try {
      emit(state.copyWith(loansStepStatusSaved: LoansStepStatus.loading));

      List<Map<String, Object?>> garantiasData;

      final loansLocalState = _preferences.getLoansPreferences;

      if (loansLocalState?.warrantyPreferences != null) {
        garantiasData = loansLocalState!.warrantyPreferences!.map((e) {
          List<String?> imagenes = [];

          for (int i = 0; i < 3; i++) {
            if (e.photoWarranty != null &&
                e.photoWarranty!.isNotEmpty &&
                i < e.photoWarranty!.length) {
              imagenes.add(e.photoWarranty![i].path);
            } else {
              imagenes.add(null);
            }
          }

          return {
            'descripcion': e.description,
            'marca': e.brand,
            'modelo': e.model,
            'placa': e.placa,
            'categoria': e.category?.descripcion ?? '',
            'color': e.color,
            'serie': e.serie,
            'valorizacion': double.parse(e.price == '' ? '0' : e.price!),
            'observaciones': e.warrantyObservations,
            'estado': e.status,
            'imagen': imagenes[0],
            'imagen2': imagenes[1],
            'imagen3': imagenes[2],
          };
        }).toList();
      } else {
        garantiasData = state.listWarranty!.map((e) {
          List<String?> imagenes = [];

          for (int i = 0; i < 3; i++) {
            if (e.photoWarranty != null &&
                e.photoWarranty!.isNotEmpty &&
                i < e.photoWarranty!.length) {
              imagenes.add(e.photoWarranty![i].path);
            } else {
              imagenes.add(null);
            }
          }

          return {
            'descripcion': e.description,
            'marca': e.brand,
            'modelo': e.model,
            'placa': e.placa,
            'categoria': e.category?.descripcion ?? '',
            'color': e.color,
            'serie': e.serie,
            'valorizacion': double.parse(e.price == '' ? '0' : e.price!),
            'observaciones': e.warrantyObservations,
            'estado': e.status,
            'imagen': imagenes[0],
            'imagen2': imagenes[1],
            'imagen3': imagenes[2],
          };
        }).toList();
      }


      final result = await _loansRepository.saveLoan(
        renew: false,
        plazoDias: int.parse(
          loansLocalState?.deadline ?? state.deadlines!,
        ),
        interes: double.parse(
          loansLocalState?.interest?.intereses ?? state.interestRate!.intereses,
        ),
        fechaPago: state.paymentDateWithoutFormatt!,
        monto: double.parse(
          loansLocalState?.amount ?? state.amount!,
        ),
        observaciones:
            loansLocalState?.observations ?? state.observations ?? '',
        cliente: CustomerEntity(
          dni: loansLocalState?.documentClient ?? state.documentClient,
          nombres: loansLocalState?.fullNamesClient ?? state.fullNamesClient,
          apellidos:
              loansLocalState?.fullLastNamesClient ?? state.fullLastNamesClient,
          domicilio: loansLocalState?.domicilioClient ?? state.homeClient,
          email: loansLocalState?.emailClient ?? state.emailClient,
          celular: loansLocalState?.phoneClient ?? state.phoneClient,
          prestamos: null,
          prestamosAval: null,
          pagos: null,
          ventas: null,
          updatedAt: '',
          createdAt: '',
          imagenUno: (loansLocalState?.imagesClient == null ||
                  loansLocalState?.imagesClient?.length == 0 ||
                  state.photosClient == null ||
                  state.photosClient?.length == 0)
              ? null
              : loansLocalState?.imagesClient?[0].path ??
                  state.photosClient?[0].path,
          imagenDos: (loansLocalState?.imagesClient == null ||
                  loansLocalState?.imagesClient?.length == 1 ||
                  state.photosClient == null ||
                  state.photosClient?.length == 1)
              ? null
              : loansLocalState?.imagesClient?[1].path ??
                  state.photosClient?[1].path,
        ),
        aval: loansLocalState?.isAval == true || state.isAval == true
            ? CustomerEntity(
                dni: loansLocalState?.documentAval ?? state.documentAval,
                nombres: loansLocalState?.fullNamesAval ?? state.fullNamesAval,
                apellidos: loansLocalState?.fullLastNamesAval ??
                    state.fullLastNamesAval,
                domicilio: loansLocalState?.domicilioAval ?? state.homeAval,
                email: loansLocalState?.emailAval ?? state.emailAval,
                celular: loansLocalState?.phoneAval ?? state.phoneAval,
                prestamos: null,
                prestamosAval: null,
                pagos: null,
                ventas: null,
                updatedAt: '',
                createdAt: '',
                imagenUno: (loansLocalState?.imagesAval == null ||
                        loansLocalState?.imagesAval?.length == 0 ||
                        state.photosAval == null ||
                        state.photosAval?.length == 0)
                    ? null
                    : loansLocalState?.imagesAval?[0].path ??
                        state.photosAval?[0].path,
                imagenDos: (loansLocalState?.imagesAval == null ||
                        loansLocalState?.imagesAval?.length == 1 ||
                        state.photosAval == null ||
                        state.photosAval?.length == 1)
                    ? null
                    : loansLocalState?.imagesAval?[1].path ??
                        state.photosAval?[1].path,
              )
            : null,
        bienes: garantiasData,
        usuarioId: event.userId,
      );

      result.fold(
        (error) => emit(
          state.copyWith(
            loansStepStatusSaved: LoansStepStatus.error,
            message: error,
          ),
        ),
        (success) => emit(
          state.copyWith(
            loansStepStatusSaved: LoansStepStatus.success,
            message: '',
            documentClient:
                loansLocalState?.documentClient ?? state.documentClient,
          ),
        ),
      );
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          loansStepStatusSaved: LoansStepStatus.error,
          message: 'Ocurrió un error, intentelo más tarde',
        ),
      );
    }
  }

  void _onSaveFirstStepOne(
    SaveFirstStepOne event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        documentClient: event.documentClient,
        fullNamesClient: event.namesClient,
        phoneClient: event.phoneClient,
        fullLastNamesClient: event.lastNamesClient,
        emailClient: event.emailClient,
        homeClient: event.domicilioClient,
        photosClient: event.photosClient,
        isAval: event.isAval,
        documentAval: event.documentAval,
        fullNamesAval: event.namesAval,
        phoneAval: event.phoneAval,
        fullLastNamesAval: event.lastNamesAval,
        emailAval: event.emailAval,
        homeAval: event.domicilioAval,
        photosAval: event.photosAval,
        index: 1,
      ),
    );
  }

  void _onSaveSecondStepOne(
    SaveSecondStepOne event,
    Emitter<LoansStepState> emit,
  ) {
    final now = DateTime.now();
    final datePay = now.add(
      Duration(
        days: int.parse(event.deadlines == '' ? '0' : event.deadlines!) - 1,
      ),
    );

    emit(
      state.copyWith(
        index: event.index,
        codeLoans: state.codeLoans,
        startDate: state.startDate,
        amount: event.amount,
        deadlines: event.deadlines,
        interestRate: event.interest,
        observations: event.observations,
        paymentDateWithoutFormatt: datePay,
      ),
    );
  }

  void _onSaveThirdStepOne(
    SaveThirdStepOne event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        index: event.index,
        description: event.value.description,
        categories: event.value.category,
        placa: event.value.placa,
        brand: event.value.brand,
        model: event.value.model,
        color: event.value.color,
        status: event.value.status,
        serie: event.value.serie,
        warrantyObservations: event.value.warrantyObservations,
        price: event.value.price,
        photoWarranty: event.value.photoWarranty,
      ),
    );
  }
}
