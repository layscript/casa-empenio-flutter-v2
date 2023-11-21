part of 'loans_step_bloc.dart';

class LoansStepState extends Equatable {
  const LoansStepState({
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
    this.interestRate,
    this.paymentDate,
    this.observations,
    this.idWarranty,
    this.brand,
    this.model,
    this.color,
    this.status,
    this.serie,
    this.warrantyObservations,
    this.price,
    this.listWarranty,
    this.addListWarranty = false,
  });

  final int index;
  //
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
  final String? interestRate;
  final String? paymentDate;
  final String? observations;

  //
  final String? idWarranty;
  final String? brand;
  final String? model;
  final String? color;
  final String? status;
  final String? serie;
  final String? warrantyObservations;
  final String? price;
  final List<Warranty>? listWarranty;
  final bool addListWarranty;
  //

  LoansStepState copyWith({
    int? index,
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
    String? interestRate,
    String? paymentDate,
    String? observations,
    String? idWarranty,
    String? brand,
    String? model,
    String? color,
    String? status,
    String? serie,
    String? warrantyObservations,
    String? price,
    List<Warranty>? listWarranty,
    bool? addListWarranty,
  }) =>
      LoansStepState(
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
        interestRate: interestRate ?? this.interestRate,
        observations: observations ?? this.observations,
        paymentDate: paymentDate ?? this.paymentDate,
        startDate: startDate ?? this.startDate,
        brand: brand ?? this.brand,
        color: color ?? this.color,
        listWarranty: listWarranty ?? this.listWarranty,
        model: model ?? this.model,
        price: price ?? this.price,
        serie: serie ?? this.serie,
        status: status ?? this.status,
        warrantyObservations: warrantyObservations ?? this.warrantyObservations,
        addListWarranty: addListWarranty ?? this.addListWarranty,
        idWarranty: idWarranty,
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
    if (interestRate!.isEmpty) return false;
    if (observations!.isEmpty) return false;
    if (paymentDate!.isEmpty) return false;
    if (startDate!.isEmpty) return false;

    return true;
  }

  bool get canRegisterWarranty {
    //if (listWarranty == null) return false;
    if (brand == null ||
        model == null ||
        color == null ||
        status == null ||
        serie == null ||
        warrantyObservations == null ||
        price == null) return false;

    if (brand!.isEmpty) return false;
    if (model!.isEmpty) return false;
    if (color!.isEmpty) return false;
    if (status!.isEmpty) return false;
    if (serie!.isEmpty) return false;
    if (warrantyObservations!.isEmpty) return false;
    if (price!.isEmpty) return false;

    return true;
  }

  @override
  List<Object?> get props => [
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
        interestRate,
        observations,
        paymentDate,
        startDate,
        idWarranty,
        brand,
        model,
        color,
        status,
        serie,
        warrantyObservations,
        price,
        listWarranty,
        addListWarranty,
      ];
}
