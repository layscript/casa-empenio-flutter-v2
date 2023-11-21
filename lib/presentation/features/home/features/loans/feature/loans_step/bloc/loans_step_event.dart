part of 'loans_step_bloc.dart';

sealed class LoansStepEvent extends Equatable {
  const LoansStepEvent();

  @override
  List<Object> get props => [];
}

// Change index steps
class ChangeIndexLoans extends LoansStepEvent {
  const ChangeIndexLoans({required this.index});
  final int index;
}

// Change one step
class ChangeHasClientAval extends LoansStepEvent {
  const ChangeHasClientAval({required this.value});
  final bool? value;
}

class ChangeDocumentClient extends LoansStepEvent {
  const ChangeDocumentClient({required this.value});
  final String value;
}

class ChangeFullNamesClient extends LoansStepEvent {
  const ChangeFullNamesClient({required this.value});
  final String value;
}

class ChangeFullLastNamesClient extends LoansStepEvent {
  const ChangeFullLastNamesClient({required this.value});
  final String value;
}

class ChangePhoneClient extends LoansStepEvent {
  const ChangePhoneClient({required this.value});
  final String value;
}

class ChangeEmailClient extends LoansStepEvent {
  const ChangeEmailClient({required this.value});
  final String value;
}

class ChangeHomeClient extends LoansStepEvent {
  const ChangeHomeClient({required this.value});
  final String value;
}

class ChangeDocumentAval extends LoansStepEvent {
  const ChangeDocumentAval({required this.value});
  final String value;
}

class ChangeFullNamesAval extends LoansStepEvent {
  const ChangeFullNamesAval({required this.value});
  final String value;
}

class ChangeFullLastNamesAval extends LoansStepEvent {
  const ChangeFullLastNamesAval({required this.value});
  final String value;
}

class ChangePhoneAval extends LoansStepEvent {
  const ChangePhoneAval({required this.value});
  final String value;
}

class ChangeEmailAval extends LoansStepEvent {
  const ChangeEmailAval({required this.value});
  final String value;
}

class ChangeHomeAval extends LoansStepEvent {
  const ChangeHomeAval({required this.value});
  final String value;
}

// second step

class ChangeCodeLoans extends LoansStepEvent {
  const ChangeCodeLoans({required this.value});
  final String value;
}

class ChangeStartDate extends LoansStepEvent {
  const ChangeStartDate({required this.value});
  final String value;
}

class ChangeAmount extends LoansStepEvent {
  const ChangeAmount({required this.value});
  final String value;
}

class ChangeDeadLines extends LoansStepEvent {
  const ChangeDeadLines({required this.value});
  final String value;
}

class ChangeInterestRate extends LoansStepEvent {
  const ChangeInterestRate({required this.value});
  final String value;
}

class ChangePaymentRate extends LoansStepEvent {
  const ChangePaymentRate({required this.value});
  final String value;
}

class ChangeObservations extends LoansStepEvent {
  const ChangeObservations({required this.value});
  final String value;
}

class ChangeBrand extends LoansStepEvent {
  const ChangeBrand({required this.value});
  final String value;
}

class ChangeModel extends LoansStepEvent {
  const ChangeModel({required this.value});
  final String value;
}

class ChangeColor extends LoansStepEvent {
  const ChangeColor({required this.value});
  final String value;
}

class ChangeStatus extends LoansStepEvent {
  const ChangeStatus({required this.value});
  final String value;
}

class ChangeSerie extends LoansStepEvent {
  const ChangeSerie({required this.value});
  final String value;
}

class ChangeWarrantyObservations extends LoansStepEvent {
  const ChangeWarrantyObservations({required this.value});
  final String value;
}

class ChangePrice extends LoansStepEvent {
  const ChangePrice({required this.value});
  final String value;
}

class AddListWarranty extends LoansStepEvent {
  const AddListWarranty({required this.value});
  final Warranty value;
}

class EditListWarranty extends LoansStepEvent {
  const EditListWarranty({required this.value});
  final Warranty value;
}

class DeleteListWarranty extends LoansStepEvent {
  const DeleteListWarranty({required this.value});
  final Warranty value;
}

class ChangeStatusAddListWarranty extends LoansStepEvent {
  const ChangeStatusAddListWarranty({required this.value});
  final bool value;
}

class ChangeStatusEditListWarranty extends LoansStepEvent {
  const ChangeStatusEditListWarranty({
    required this.value,
    required this.id,
  });
  final bool value;
  final String id;
}
