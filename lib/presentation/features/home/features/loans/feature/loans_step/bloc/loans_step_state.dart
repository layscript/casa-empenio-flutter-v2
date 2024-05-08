part of 'loans_step_bloc.dart';

enum LoansStepStatus { initial, loading, loaded, error, success }

class WarrantyState {
  const WarrantyState({
    required this.id,
    required this.description,
    required this.category,
    required this.placa,
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
  final CategoriesEntity? category;
  final String? placa;
  final String? description;
  final String? brand;
  final String? model;
  final String? color;
  final String? status;
  final String? serie;
  final String? warrantyObservations;
  final String? price;
  final List<XFile>? photoWarranty;

  factory WarrantyState.fromJson(Map<String, dynamic> json) {
    return WarrantyState(
      id: json['id'],
      description: json['description'],
      category: json['category'] != null
          ? CategoriesEntity(
              id: json['category']['id'],
              descripcion: json['category']['descripcion'],
              updatedAt: json['category']['updatedAt'],
              createdAt: json['category']['createdAt'],
            )
          : null,
      placa: json['placa'],
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
      status: json['status'],
      serie: json['serie'],
      warrantyObservations: json['warrantyObservations'],
      price: json['price'],
      photoWarranty: json['photoWarranty'] != null
          ? (json['photoWarranty'] as List<dynamic>)
              .map((path) => XFile(path))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category != null
          ? {
              'id': category?.id,
              'descripcion': category?.descripcion,
              'updatedAt': category?.updatedAt,
              'createdAt': category?.createdAt,
            }
          : null,
      'placa': placa,
      'description': description,
      'brand': brand,
      'model': model,
      'color': color,
      'status': status,
      'serie': serie,
      'warrantyObservations': warrantyObservations,
      'price': price,
      'photoWarranty': photoWarranty?.map((xFile) => xFile.path).toList(),
    };
  }
}

class LoansStepState extends Equatable {
  const LoansStepState({
    this.loansStepStatus = LoansStepStatus.initial,
    this.loansStepStatusSaved = LoansStepStatus.initial,
    this.message,
    this.index = 0,
    this.isAval = false,
    this.documentClient,
    this.fullNamesClient,
    this.fullLastNamesClient,
    this.phoneClient,
    this.emailClient,
    this.homeClient,
    this.photosClient,
    this.documentAval,
    this.fullNamesAval,
    this.fullLastNamesAval,
    this.phoneAval,
    this.emailAval,
    this.homeAval,
    this.photosAval,
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
    this.listCategories,
    this.categories,
    this.idWarranty,
    this.description,
    this.brand,
    this.model,
    this.placa,
    this.color,
    this.status,
    this.serie,
    this.warrantyObservations,
    this.price,
    this.listWarranty,
    this.addListWarranty = false,
    this.photoWarranty,
    this.cajaId,
  });

  final LoansStepStatus loansStepStatus;
  final LoansStepStatus loansStepStatusSaved;
  final String? message;
  final int index;
  final bool? isAval;
  final String? documentClient;
  final String? fullNamesClient;
  final String? phoneClient;
  final String? fullLastNamesClient;
  final String? emailClient;
  final String? homeClient;
  final List<XFile>? photosClient;

  final String? documentAval;
  final String? fullNamesAval;
  final String? phoneAval;
  final String? fullLastNamesAval;
  final String? emailAval;
  final String? homeAval;
  final List<XFile>? photosAval;

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
  final List<CategoriesEntity>? listCategories;
  final CategoriesEntity? categories;
  final String? idWarranty;
  final String? description;
  final String? brand;
  final String? model;
  final String? placa;
  final String? color;
  final String? status;
  final String? serie;
  final String? warrantyObservations;
  final String? price;
  final List<WarrantyState>? listWarranty;
  final bool addListWarranty;
  final List<XFile>? photoWarranty;

  final int? cajaId;

  //

  bool get isLoansStepLoading => loansStepStatus == LoansStepStatus.loading;
  bool get isLoansStepError => loansStepStatus == LoansStepStatus.error;
  bool get isLoansStepSuccess => loansStepStatus == LoansStepStatus.success;

  bool get isLoansStepStatusSavedLoading =>
      loansStepStatusSaved == LoansStepStatus.loading;

  bool get isLoansStepStatusSavedError =>
      loansStepStatusSaved == LoansStepStatus.error;

  bool get isLoansStepStatusSavedSuccess =>
      loansStepStatusSaved == LoansStepStatus.success;
  //

  /*  @override
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
 */
  LoansStepState copyWith({
    int? lastCode,
    LoansStepStatus? loansStepStatus,
    LoansStepStatus? loansStepStatusSaved,
    int? index,
    String? message,
    bool? isAval,
    String? documentClient,
    String? fullNamesClient,
    String? phoneClient,
    String? fullLastNamesClient,
    String? emailClient,
    String? homeClient,
    List<XFile>? photosClient,
    String? documentAval,
    String? fullNamesAval,
    String? phoneAval,
    String? fullLastNamesAval,
    String? emailAval,
    String? homeAval,
    List<XFile>? photosAval,
    String? codeLoans,
    String? startDate,
    String? amount,
    String? deadlines,
    List<InterestsEntity>? listInterests,
    List<CategoriesEntity>? listCategories,
    InterestsEntity? interestRate,
    CategoriesEntity? categories,
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
    List<XFile>? photoWarranty,
    String? placa,
    int? cajaId,
  }) =>
      LoansStepState(
        loansStepStatus: loansStepStatus ?? this.loansStepStatus,
        loansStepStatusSaved: loansStepStatusSaved ?? this.loansStepStatusSaved,
        message: message ?? this.message,
        index: index ?? this.index,
        isAval: isAval ?? this.isAval,
        documentClient: documentClient ?? this.documentClient,
        fullNamesClient: fullNamesClient ?? this.fullNamesClient,
        fullLastNamesClient: fullLastNamesClient ?? this.fullLastNamesClient,
        emailClient: emailClient ?? this.emailClient,
        homeClient: homeClient ?? this.homeClient,
        phoneClient: phoneClient ?? this.phoneClient,
        photosClient: photosClient ?? this.photosClient,
        documentAval: documentAval ?? this.documentAval,
        fullNamesAval: fullNamesAval ?? this.fullNamesAval,
        fullLastNamesAval: fullLastNamesAval ?? this.fullLastNamesAval,
        emailAval: emailAval ?? this.emailAval,
        homeAval: homeAval ?? this.homeAval,
        phoneAval: phoneAval ?? this.phoneAval,
        photosAval: photosAval ?? this.photosAval,
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
        status: status ?? this.status,
        warrantyObservations: warrantyObservations ?? this.warrantyObservations,
        addListWarranty: addListWarranty ?? this.addListWarranty,
        idWarranty: idWarranty,
        description: description ?? this.description,
        totalToPay: totalToPay ?? this.totalToPay,
        totalProfit: totalProfit ?? this.totalProfit,
        photoWarranty: photoWarranty ?? this.photoWarranty,
        listCategories: listCategories ?? this.listCategories,
        categories: categories ?? this.categories,
        placa: placa ?? this.placa,
        cajaId: cajaId ?? this.cajaId,
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
        loansStepStatusSaved,
        message,
        isAval,
        index,
        documentClient,
        fullNamesClient,
        fullLastNamesClient,
        emailClient,
        homeClient,
        phoneClient,
        photosAval,
        documentAval,
        fullNamesAval,
        fullLastNamesAval,
        emailAval,
        homeAval,
        phoneAval,
        photosAval,
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
        listCategories,
        categories,
        placa,
        cajaId,
      ];
}
