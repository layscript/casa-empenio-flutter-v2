part of 'loans_step_bloc.dart';

sealed class LoansStepEvent extends Equatable {
  const LoansStepEvent();

  @override
  List<Object> get props => [];
}

class GetApiSunatByDNI extends LoansStepEvent {
  const GetApiSunatByDNI(this.document);
  final String document;
}

class SaveTempDataLoans extends LoansStepEvent {
  const SaveTempDataLoans();
}

// SaveFirstStepOne
class SaveFirstStepOne extends LoansStepEvent {
  const SaveFirstStepOne();
}

class SaveSecondStepOne extends LoansStepEvent {
  const SaveSecondStepOne({
    required this.index,
  });

  final int index;
}

class SaveThirdStepOne extends LoansStepEvent {
  const SaveThirdStepOne({
    required this.index,
    required this.value,
  });
  final int index;
  final WarrantyState value;
}

// Gets Loans
class GetLastCodeLoans extends LoansStepEvent {}

// Change index steps

class ChangePhotosClient extends LoansStepEvent {
  const ChangePhotosClient({required this.photosClient});
  final List<XFile>? photosClient;
}

class ChangePhotosAval extends LoansStepEvent {
  const ChangePhotosAval({required this.photosAval});
  final List<XFile>? photosAval;
}

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
  final InterestsEntity? value;
}

class ChangePaymentRate extends LoansStepEvent {
  const ChangePaymentRate({required this.value});
  final String value;
}

class ChangeObservations extends LoansStepEvent {
  const ChangeObservations({required this.value});
  final String value;
}

class ChangeDescription extends LoansStepEvent {
  const ChangeDescription({
    required this.value,
    this.edit = false,
  });
  final String value;
  final bool edit;
}

class ChangeCategoryWarranty extends LoansStepEvent {
  final CategoriesEntity? value;
  const ChangeCategoryWarranty(this.value);
}

class ChangePlacaWarranty extends LoansStepEvent {
  final String value;
  const ChangePlacaWarranty(this.value);
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
  const AddListWarranty();
}

class EditListWarranty extends LoansStepEvent {
  const EditListWarranty();
}

class DeleteListWarranty extends LoansStepEvent {
  const DeleteListWarranty({
    required this.value,
    required this.localState,
  });
  final WarrantyState value;
  final LoansPreferencesEntity localState;
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

class UploadImagesWarranty extends LoansStepEvent {
  final List<XFile>? value;
  const UploadImagesWarranty(this.value);
}

class SaveAllLoan extends LoansStepEvent {
  const SaveAllLoan(this.userId);
  final String userId;
}
