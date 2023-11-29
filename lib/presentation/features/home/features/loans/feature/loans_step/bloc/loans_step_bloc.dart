import 'dart:async';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

part 'loans_step_event.dart';
part 'loans_step_state.dart';

class LoansStepBloc extends Bloc<LoansStepEvent, LoansStepState> {
  LoansStepBloc({
    required LoansRepository loansRepository,
    required InterestsRepository interestsRepository,
  })  : _loansRepository = loansRepository,
        _interestsRepository = interestsRepository,
        super(const LoansStepState()) {
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

  void _onChangeIndexLoans(
    ChangeIndexLoans event,
    Emitter<LoansStepState> emit,
  ) {
    emit(state.copyWith(index: event.index));
  }

  // one step - client
  void _onChangeDocumentClient(
    ChangeDocumentClient event,
    Emitter<LoansStepState> emit,
  ) {
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
  ) {
    List<WarrantyState>? newList;
    if (state.listWarranty != null) {
      newList = [...state.listWarranty!, event.value];
    } else {
      newList = [event.value];
    }
    emit(
      state.copyWith(
        listWarranty: newList,
        addListWarranty: false,
        idWarranty: null,
      ),
    );
  }

  void _onEditListWarranty(
    EditListWarranty event,
    Emitter<LoansStepState> emit,
  ) {
    final updateWarranty = event.value;

    if (state.listWarranty != null) {
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
    }
  }

  void _onDeleteListWarranty(
    DeleteListWarranty event,
    Emitter<LoansStepState> emit,
  ) {
    final deleteWarranty = event.value;
    final newList =
        state.listWarranty?.where((e) => e.id != deleteWarranty.id).toList();

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

  void _onChangeStatusAddListWarranty(
    ChangeStatusAddListWarranty event,
    Emitter<LoansStepState> emit,
  ) {
    emit(
      state.copyWith(
        addListWarranty: event.value,
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

  void _onChangeStatusEditListWarranty(
    ChangeStatusEditListWarranty event,
    Emitter<LoansStepState> emit,
  ) {
    final filterData = state.listWarranty!.firstWhere(
      (e) => e.id == event.id,
    );

    emit(
      state.copyWith(
        addListWarranty: event.value,
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
    ]);

    final formattedDate = _onGetToday();
    final resultLastCode = result[0] as Either<String, int>;
    final resultListInterest =
        result[1] as Either<String, List<InterestsEntity>>;

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
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    emit(
      state.copyWith(
        photoWarranty: photo,
        idWarranty: state.idWarranty,
        status: state.status,
      ),
    );
  }

  Future<void> _onSaveAllLoan(
    SaveAllLoan event,
    Emitter<LoansStepState> emit,
  ) async {
    final garantiasData = state.listWarranty!.map((e) {
      return {
        'descripcion': e.description,
        'marca': e.brand,
        'modelo': e.model,
        'color': e.color,
        'serie': e.serie,
        'valorizacion': double.parse(e.price == '' ? '0' : e.price!),
        'observaciones': e.warrantyObservations,
        'estado': e.status,
        'imagen': e.photoWarranty!.path,
      };
    }).toList();

    // TODO:: Falta api para guardar y probar
    await _loansRepository.saveLoan(
      plazoDias: int.parse(state.deadlines!),
      interes: double.parse(state.interestRate!.intereses),
      fechaPago: state.paymentDateWithoutFormatt!,
      monto: double.parse(state.amount!),
      observaciones: state.observations!,
      cliente: CustomerEntity(
        dni: state.documentClient,
        nombres: state.fullNamesClient,
        apellidos: state.fullLastNamesClient,
        domicilio: state.homeClient,
        email: state.emailClient,
        celular: state.phoneClient,
        prestamos: null,
        prestamosAval: null,
        pagos: null,
        ventas: null,
        updatedAt: '',
        createdAt: '',
      ),
      aval: state.isAval == true
          ? CustomerEntity(
              dni: state.documentAval,
              nombres: state.fullNamesAval,
              apellidos: state.fullLastNamesAval,
              domicilio: state.homeAval,
              email: state.emailAval,
              celular: state.phoneAval,
              prestamos: null,
              prestamosAval: null,
              pagos: null,
              ventas: null,
              updatedAt: '',
              createdAt: '',
            )
          : null,
      bienes: garantiasData,
      usuarioId: event.userId,
    );
  }
}
