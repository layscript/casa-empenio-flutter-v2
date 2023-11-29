part of 'loans_step_bloc.dart';

enum LoansStepStatus { initial, loading, loaded, error }

class WarrantyState {
  const WarrantyState({
    required this.id,
    required this.description,
    required this.brand,
    required this.model,
    required this.color,
    required this.status,
    required this.serie,
    required this.warrantyObservations,
    required this.price,
    required this.photoWarranty,
  });

  final String? id;
  final String? description;
  final String? brand;
  final String? model;
  final String? color;
  final String? status;
  final String? serie;
  final String? warrantyObservations;
  final String? price;
  final XFile? photoWarranty;
}

class LoansStepState extends Equatable {
  const LoansStepState({
    this.loansStepStatus = LoansStepStatus.initial,
    this.message,
    this.index = 0,
    this.isAval = false,
    this.documentClient,
    this.fullNamesClient,
    this.fullLastNamesClient,
    this.phoneClient,
    this.emailClient,
    this.homeClient,
    this.documentAval,
    this.fullNamesAval,
    this.fullLastNamesAval,
    this.phoneAval,
    this.emailAval,
    this.homeAval,
    this.codeLoans,
    this.startDate,
    this.amount,
    this.deadlines,
    this.listInterests,
    this.interestRate,
    this.paymentDate,
    this.paymentDateWithoutFormatt,
    this.observations,
    this.totalToPay,
    this.totalProfit,
    this.idWarranty,
    this.description,
    this.brand,
    this.model,
    this.color,
    this.status,
    this.serie,
    this.warrantyObservations,
    this.price,
    this.listWarranty,
    this.addListWarranty = false,
    this.photoWarranty,
  });

  final LoansStepStatus loansStepStatus;
  final String? message;
  final int index;
  final bool? isAval;
  final String? documentClient;
  final String? fullNamesClient;
  final String? phoneClient;
  final String? fullLastNamesClient;
  final String? emailClient;
  final String? homeClient;
  final String? documentAval;
  final String? fullNamesAval;
  final String? phoneAval;
  final String? fullLastNamesAval;
  final String? emailAval;
  final String? homeAval;

  //
  final String? codeLoans;
  final String? startDate;
  final String? amount;
  final String? deadlines;
  final List<InterestsEntity>? listInterests;
  final InterestsEntity? interestRate;
  final String? paymentDate;
  final DateTime? paymentDateWithoutFormatt;
  final String? observations;
  final String? totalToPay;
  final String? totalProfit;

  //
  final String? idWarranty;
  final String? description;
  final String? brand;
  final String? model;
  final String? color;
  final String? status;
  final String? serie;
  final String? warrantyObservations;
  final String? price;
  final List<WarrantyState>? listWarranty;
  final bool addListWarranty;
  final XFile? photoWarranty;

  //

  bool get isLoansStepLoading => loansStepStatus == LoansStepStatus.loading;
  bool get isLoansStepError => loansStepStatus == LoansStepStatus.error;

  //

  @override
  String toString() {
    return '''{
   loansStepStatus: $loansStepStatus,   
   message: $message,   
   index: $index,   
   isAval: $isAval,   
   documentClient: $documentClient,   
   fullNamesClient: $fullNamesClient,   
   phoneClient: $phoneClient, 
   fullLastNamesClient: $fullLastNamesClient,   
   emailClient: $emailClient,   
   homeClient: $homeClient,   
   documentAval: $documentAval,   
   fullNamesAval: $fullNamesAval,   
   phoneAval: $phoneAval,   
   fullLastNamesAval: $fullLastNamesAval,
   emailAval: $emailAval,
   homeAval: $homeAval,
   codeLoans: $codeLoans, 
   startDate: $startDate,
   amount: $amount,   
   deadlines: $deadlines,   
   listInterests: $listInterests,   
   interestRate: $interestRate,   
   paymentDate: $paymentDate, 
   paymentDateWithoutFormatt: $paymentDateWithoutFormatt,  
   observations: $observations,
   totalToPay: $totalToPay,
   totalProfit: $totalProfit,
   description: $description,
   idWarranty: $idWarranty,
   brand: $brand;
   model: $model,
   color: $color,
   status: $status,
   serie: $serie,
   warrantyObservations: $warrantyObservations,
   price: $price,
   listWarranty: $listWarranty,
   addListWarranty: $addListWarranty,
}''';
  }

  LoansStepState copyWith({
    int? lastCode,
    LoansStepStatus? loansStepStatus,
    int? index,
    String? message,
    bool? isAval,
    String? documentClient,
    String? fullNamesClient,
    String? phoneClient,
    String? fullLastNamesClient,
    String? emailClient,
    String? homeClient,
    String? documentAval,
    String? fullNamesAval,
    String? phoneAval,
    String? fullLastNamesAval,
    String? emailAval,
    String? homeAval,
    String? codeLoans,
    String? startDate,
    String? amount,
    String? deadlines,
    List<InterestsEntity>? listInterests,
    InterestsEntity? interestRate,
    String? paymentDate,
    DateTime? paymentDateWithoutFormatt,
    String? observations,
    String? idWarranty,
    String? description,
    String? brand,
    String? model,
    String? color,
    String? status,
    String? serie,
    String? warrantyObservations,
    String? price,
    List<WarrantyState>? listWarranty,
    bool? addListWarranty,
    String? totalToPay,
    String? totalProfit,
    XFile? photoWarranty,
  }) =>
      LoansStepState(
        loansStepStatus: loansStepStatus ?? this.loansStepStatus,
        message: message ?? this.message,
        index: index ?? this.index,
        isAval: isAval ?? this.isAval,
        documentClient: documentClient ?? this.documentClient,
        fullNamesClient: fullNamesClient ?? this.fullNamesClient,
        fullLastNamesClient: fullLastNamesClient ?? this.fullLastNamesClient,
        emailClient: emailClient ?? this.emailClient,
        homeClient: homeClient ?? this.homeClient,
        phoneClient: phoneClient ?? this.phoneClient,
        documentAval: documentAval ?? this.documentAval,
        fullNamesAval: fullNamesAval ?? this.fullNamesAval,
        fullLastNamesAval: fullLastNamesAval ?? this.fullLastNamesAval,
        emailAval: emailAval ?? this.emailAval,
        homeAval: homeAval ?? this.homeAval,
        phoneAval: phoneAval ?? this.phoneAval,
        amount: amount ?? this.amount,
        codeLoans: codeLoans ?? this.codeLoans,
        deadlines: deadlines ?? this.deadlines,
        listInterests: listInterests ?? this.listInterests,
        interestRate: interestRate ?? this.interestRate,
        observations: observations ?? this.observations,
        paymentDate: paymentDate ?? this.paymentDate,
        paymentDateWithoutFormatt:
            paymentDateWithoutFormatt ?? this.paymentDateWithoutFormatt,
        startDate: startDate ?? this.startDate,
        brand: brand ?? this.brand,
        color: color ?? this.color,
        listWarranty: listWarranty ?? this.listWarranty,
        model: model ?? this.model,
        price: price ?? this.price,
        serie: serie ?? this.serie,
        status: status,
        warrantyObservations: warrantyObservations ?? this.warrantyObservations,
        addListWarranty: addListWarranty ?? this.addListWarranty,
        idWarranty: idWarranty,
        description: description ?? this.description,
        totalToPay: totalToPay ?? this.totalToPay,
        totalProfit: totalProfit ?? this.totalProfit,
        photoWarranty: photoWarranty,
      );

  String titleIndexLoans() {
    if (index == 0) return 'Datos del Cliente';
    if (index == 1) return 'Préstamo';
    if (index == 2) return 'Garantía';
    return '';
  }

  bool get canRegisterClient {
    if (documentClient == null ||
        fullNamesClient == null ||
        fullLastNamesClient == null ||
        emailClient == null ||
        homeClient == null ||
        phoneClient == null) return false;
    if (documentClient!.isEmpty || documentClient!.length < 8) return false;
    if (fullNamesClient!.isEmpty) return false;
    if (phoneClient!.isEmpty || phoneClient!.length < 9) return false;
    if (fullLastNamesClient!.isEmpty) return false;
    if (emailClient!.isEmpty || !validatorEmail(emailClient!)) return false;
    if (homeClient!.isEmpty) return false;

    if (isAval == true) {
      if (documentAval == null ||
          fullNamesAval == null ||
          fullLastNamesAval == null ||
          emailAval == null ||
          homeAval == null ||
          phoneAval == null) return false;
      if (documentAval!.isEmpty || documentAval!.length < 8) return false;
      if (fullNamesAval!.isEmpty) return false;
      if (phoneAval!.isEmpty || phoneAval!.length < 9) return false;
      if (fullLastNamesAval!.isEmpty) return false;
      if (emailAval!.isEmpty || !validatorEmail(emailAval!)) return false;
      if (homeAval!.isEmpty) return false;
    }

    return true;
  }

  bool get canRegisterLoans {
    if (amount == null ||
        codeLoans == null ||
        deadlines == null ||
        interestRate == null ||
        observations == null ||
        paymentDate == null ||
        startDate == null) return false;

    if (codeLoans!.isEmpty) return false;
    if (amount!.isEmpty) return false;
    if (deadlines!.isEmpty) return false;
    if (interestRate == null) return false;
    if (observations!.isEmpty) return false;
    if (paymentDate!.isEmpty) return false;
    if (startDate!.isEmpty) return false;

    return true;
  }

  bool get canRegisterWarranty {
    //if (listWarranty == null) return false;
    if (description == null ||
        brand == null ||
        model == null ||
        color == null ||
        status == null ||
        serie == null ||
        warrantyObservations == null ||
        price == null ||
        photoWarranty == null) return false;

    if (description!.isEmpty) return false;
    if (brand!.isEmpty) return false;
    if (model!.isEmpty) return false;
    if (color!.isEmpty) return false;
    if (status!.isEmpty) return false;
    if (serie!.isEmpty) return false;
    if (warrantyObservations!.isEmpty) return false;
    if (price!.isEmpty) return false;
    if (photoWarranty == null) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        loansStepStatus,
        message,
        isAval,
        index,
        documentClient,
        fullNamesClient,
        fullLastNamesClient,
        emailClient,
        homeClient,
        phoneClient,
        documentAval,
        fullNamesAval,
        fullLastNamesAval,
        emailAval,
        homeAval,
        phoneAval,
        amount,
        codeLoans,
        deadlines,
        listInterests,
        interestRate,
        observations,
        paymentDate,
        paymentDateWithoutFormatt,
        startDate,
        idWarranty,
        description,
        brand,
        model,
        color,
        status,
        serie,
        warrantyObservations,
        price,
        listWarranty,
        addListWarranty,
        totalToPay,
        totalProfit,
        photoWarranty,
      ];
}
