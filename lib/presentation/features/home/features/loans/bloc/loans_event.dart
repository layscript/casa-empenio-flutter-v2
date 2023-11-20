part of 'loans_bloc.dart';

sealed class LoansEvent extends Equatable {
  const LoansEvent();

  @override
  List<Object> get props => [];
}

// Change index steps
class ChangeIndexLoans extends LoansEvent {
  const ChangeIndexLoans({required this.index});
  final int index;
}

// Change one step
class ChangeHasClientAval extends LoansEvent {
  const ChangeHasClientAval({required this.value});
  final bool? value;
}

class ChangeDocumentClient extends LoansEvent {
  const ChangeDocumentClient({required this.value});
  final String value;
}

class ChangeFullNamesClient extends LoansEvent {
  const ChangeFullNamesClient({required this.value});
  final String value;
}

class ChangeFullLastNamesClient extends LoansEvent {
  const ChangeFullLastNamesClient({required this.value});
  final String value;
}

class ChangePhoneClient extends LoansEvent {
  const ChangePhoneClient({required this.value});
  final String value;
}

class ChangeEmailClient extends LoansEvent {
  const ChangeEmailClient({required this.value});
  final String value;
}

class ChangeHomeClient extends LoansEvent {
  const ChangeHomeClient({required this.value});
  final String value;
}

class ChangeDocumentAval extends LoansEvent {
  const ChangeDocumentAval({required this.value});
  final String value;
}

class ChangeFullNamesAval extends LoansEvent {
  const ChangeFullNamesAval({required this.value});
  final String value;
}

class ChangeFullLastNamesAval extends LoansEvent {
  const ChangeFullLastNamesAval({required this.value});
  final String value;
}

class ChangePhoneAval extends LoansEvent {
  const ChangePhoneAval({required this.value});
  final String value;
}

class ChangeEmailAval extends LoansEvent {
  const ChangeEmailAval({required this.value});
  final String value;
}

class ChangeHomeAval extends LoansEvent {
  const ChangeHomeAval({required this.value});
  final String value;
}

// second step

class ChangeCodeLoans extends LoansEvent {
  const ChangeCodeLoans({required this.value});
  final String value;
}

class ChangeStartDate extends LoansEvent {
  const ChangeStartDate({required this.value});
  final String value;
}

class ChangeAmount extends LoansEvent {
  const ChangeAmount({required this.value});
  final String value;
}

class ChangeDeadLines extends LoansEvent {
  const ChangeDeadLines({required this.value});
  final String value;
}

class ChangeInterestRate extends LoansEvent {
  const ChangeInterestRate({required this.value});
  final String value;
}

class ChangePaymentRate extends LoansEvent {
  const ChangePaymentRate({required this.value});
  final String value;
}

class ChangeObservations extends LoansEvent {
  const ChangeObservations({required this.value});
  final String value;
}

class ChangeBrand extends LoansEvent {
  const ChangeBrand({required this.value});
  final String value;
}

class ChangeModel extends LoansEvent {
  const ChangeModel({required this.value});
  final String value;
}

class ChangeColor extends LoansEvent {
  const ChangeColor({required this.value});
  final String value;
}

class ChangeStatus extends LoansEvent {
  const ChangeStatus({required this.value});
  final String value;
}

class ChangeSerie extends LoansEvent {
  const ChangeSerie({required this.value});
  final String value;
}

class ChangeWarrantyObservations extends LoansEvent {
  const ChangeWarrantyObservations({required this.value});
  final String value;
}

class ChangePrice extends LoansEvent {
  const ChangePrice({required this.value});
  final String value;
}

class AddListWarranty extends LoansEvent {
  const AddListWarranty({required this.value});
  final Warranty value;
}

class EditListWarranty extends LoansEvent {
  const EditListWarranty({required this.value});
  final Warranty value;
}

class DeleteListWarranty extends LoansEvent {
  const DeleteListWarranty({required this.value});
  final Warranty value;
}

class ChangeStatusAddListWarranty extends LoansEvent {
  const ChangeStatusAddListWarranty({required this.value});
  final bool value;
}

class ChangeStatusEditListWarranty extends LoansEvent {
  const ChangeStatusEditListWarranty({
    required this.value,
    required this.id,
  });
  final bool value;
  final String id;
}
