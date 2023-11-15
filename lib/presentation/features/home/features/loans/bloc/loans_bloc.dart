import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'loans_event.dart';
part 'loans_state.dart';

class LoansBloc extends Bloc<LoansEvent, LoansState> {
  LoansBloc() : super(const LoansState()) {
    on<ChangeIndexLoans>(_onChangeIndexLoans);
    on<ChangeDocument>(_onChangeDocument);
    on<ChangeFullNames>(_onChangeFullNames);
    on<ChangeFullLastNames>(_onChangeFullLastNames);
    on<ChangePhone>(_onChangePhone);
    on<ChangeEmail>(_onChangeEmail);
    on<ChangeHome>(_onChangeHome);
    on<ChangeCodeLoans>(_onChangeCodeLoans);
    on<ChangeStartDate>(_onChangeStartDate);
    on<ChangeAmount>(_onChangeAmount);
    on<ChangeDeadLines>(_onChangeDeadLines);
    on<ChangeInterestRate>(_onChangeInterestRate);
    on<ChangePaymentRate>(_onChangePaymentRate);
    on<ChangeObservations>(_onChangeObservations);
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
  }

  void _onChangeIndexLoans(
    ChangeIndexLoans event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(index: event.index));
  }

  void _onChangeDocument(
    ChangeDocument event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(document: event.value));
  }

  void _onChangeFullNames(
    ChangeFullNames event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(fullNames: event.value));
  }

  void _onChangeFullLastNames(
    ChangeFullLastNames event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(fullLastNames: event.value));
  }

  void _onChangePhone(
    ChangePhone event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(phone: event.value));
  }

  void _onChangeEmail(
    ChangeEmail event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(email: event.value));
  }

  void _onChangeHome(
    ChangeHome event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(home: event.value));
  }

  void _onChangeCodeLoans(
    ChangeCodeLoans event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(codeLoans: event.value));
  }

  void _onChangeStartDate(
    ChangeStartDate event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(startDate: event.value));
  }

  void _onChangeAmount(
    ChangeAmount event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(amount: event.value));
  }

  void _onChangeDeadLines(
    ChangeDeadLines event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(deadlines: event.value));
  }

  void _onChangeInterestRate(
    ChangeInterestRate event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(interestRate: event.value));
  }

  void _onChangePaymentRate(
    ChangePaymentRate event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(paymentDate: event.value));
  }

  void _onChangeObservations(
    ChangeObservations event,
    Emitter<LoansState> emit,
  ) {
    emit(state.copyWith(observations: event.value));
  }

  void _onChangeBrand(
    ChangeBrand event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        brand: event.value,
        idWarranty: state.idWarranty,
      ),
    );
  }

  void _onChangeModel(
    ChangeModel event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        model: event.value,
        idWarranty: state.idWarranty,
      ),
    );
  }

  void _onChangeColor(
    ChangeColor event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        color: event.value,
        idWarranty: state.idWarranty,
      ),
    );
  }

  void _onChangeStatus(
    ChangeStatus event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        status: event.value,
        idWarranty: state.idWarranty,
      ),
    );
  }

  void _onChangeSerie(
    ChangeSerie event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        serie: event.value,
        idWarranty: state.idWarranty,
      ),
    );
  }

  void _onChangeWarrantyObservations(
    ChangeWarrantyObservations event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        warrantyObservations: event.value,
        idWarranty: state.idWarranty,
      ),
    );
  }

  void _onChangePrice(
    ChangePrice event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        price: event.value,
        idWarranty: state.idWarranty,
      ),
    );
  }

  void _onAddListWarranty(
    AddListWarranty event,
    Emitter<LoansState> emit,
  ) {
    List<Warranty>? newList;
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
    Emitter<LoansState> emit,
  ) {
    final updateWarranty = event.value;

    if (state.listWarranty != null) {
      final updatedList = List<Warranty>.from(state.listWarranty!);
      final index = updatedList.indexWhere((e) => e.id == updateWarranty.id);

      if (index != -1) {
        updatedList[index] = updateWarranty;
        //emit(LoansState(listWarranty: updatedList));
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
    Emitter<LoansState> emit,
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
        status: '',
        idWarranty: null,
      ),
    );
  }

  void _onChangeStatusAddListWarranty(
    ChangeStatusAddListWarranty event,
    Emitter<LoansState> emit,
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
        status: '',
        idWarranty: null,
      ),
    );
  }

  void _onChangeStatusEditListWarranty(
    ChangeStatusEditListWarranty event,
    Emitter<LoansState> emit,
  ) {
    emit(
      state.copyWith(
        addListWarranty: event.value,
        idWarranty: event.id,
      ),
    );
  }
}
