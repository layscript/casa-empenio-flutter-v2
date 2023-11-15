part of 'loans_bloc.dart';

class LoansState extends Equatable {
  const LoansState({
    this.index = 0,
    this.document,
    this.fullNames,
    this.fullLastNames,
    this.phone,
    this.email,
    this.home,
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
  final String? document;
  final String? fullNames;
  final String? phone;
  final String? fullLastNames;
  final String? email;
  final String? home;

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

  LoansState copyWith({
    int? index,
    String? document,
    String? fullNames,
    String? phone,
    String? fullLastNames,
    String? email,
    String? home,
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
      LoansState(
        index: index ?? this.index,
        document: document ?? this.document,
        fullNames: fullNames ?? this.fullNames,
        fullLastNames: fullLastNames ?? this.fullLastNames,
        email: email ?? this.email,
        home: home ?? this.home,
        phone: phone ?? this.phone,
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
    if (document == null ||
        fullNames == null ||
        fullLastNames == null ||
        email == null ||
        home == null ||
        phone == null) return false;
    if (document!.isEmpty || document!.length < 8) return false;
    if (fullNames!.isEmpty) return false;
    if (phone!.isEmpty || phone!.length < 9) return false;
    if (fullLastNames!.isEmpty) return false;
    if (email!.isEmpty || !validatorEmail(email!)) return false;
    if (home!.isEmpty) return false;

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
        index,
        document,
        fullNames,
        fullLastNames,
        email,
        home,
        phone,
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
