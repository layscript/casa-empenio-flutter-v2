part of 'loans_bloc.dart';

enum LoansStatus {
  initial,
  loading,
  error,
  loaded,

  paymentSuccess,
  paymentError,

  settlementSuccess,
  settlementError,

  addAmountLoading,
  addAmountSuccess,
  addAmountError,

  electronicTicketLoading,
  electronicTicketSuccess,
  electronicTicketError,

  ///
  loadingDetailsLoan,
  loadingDetailsSunat,

  searchClientLoading,
  searchClientSuccess,
  searchClientError,

  //
  deleteLoanLoading,
  deleteLoanSuccess,
  deleteLoanError,

  //
  updateStatusLoanLoading,
  updateStatusLoanSuccess,
  updateStatusLoanError,

  //
  updateLoansLoading,
  updateLoansSuccess,
  updateLoansError,
}

enum AnexosLoanStatus {
  initial,
  loading,
  success,
  error,
}

class LoansState extends Equatable {
  const LoansState({
    this.searchText = '',
    this.openBox = false,
    this.typeSearch,
    this.loansStatus = LoansStatus.initial,
    this.loansSearchStatus = LoansStatus.initial,
    this.loansRenewStatus = LoansStatus.initial,
    this.solicitudStatus = LoansStatus.initial,
    this.anexosLoanStatus = AnexosLoanStatus.initial,
    this.listAnexosStatus = AnexosLoanStatus.initial,
    this.listAnexos = const <AnexoEntity>[],
    this.customer,
    this.searchCustomer,
    this.customerSunat,
    this.error,
    this.loanDetails,
    this.listCategories,
    this.cajaId,
  });

  final bool? openBox;
  final bool? typeSearch;
  final String searchText;

  final AnexosLoanStatus anexosLoanStatus;
  final List<AnexoEntity> listAnexos;
  final AnexosLoanStatus listAnexosStatus;

  final LoansStatus loansStatus;
  final LoansStatus loansSearchStatus;
  final LoansStatus? loansRenewStatus;
  final LoansStatus? solicitudStatus;
  final CustomerEntity? customer;
  final CustomerEntity? searchCustomer;
  final CustomerSunatEntity? customerSunat;
  final String? error;
  final LoansEntity? loanDetails;
  final List<CategoriesEntity>? listCategories;
  final int? cajaId;

  bool get isLoadingDetailsLoan =>
      loansStatus == LoansStatus.loadingDetailsLoan;

  bool get isLoadingDetailsSunat =>
      loansStatus == LoansStatus.loadingDetailsSunat;

  bool get isLoansLoading => loansStatus == LoansStatus.loading;
  bool get isLoansError => loansStatus == LoansStatus.error;
  bool get isLoansLoaded => loansStatus == LoansStatus.loaded;

  bool get isLoansPaymentSuccess => loansStatus == LoansStatus.paymentSuccess;
  bool get isLoansPaymentError => loansStatus == LoansStatus.paymentError;

  bool get isLoansSettlementSuccess =>
      loansStatus == LoansStatus.settlementSuccess;
  bool get isLoansSettlementError => loansStatus == LoansStatus.settlementError;

  bool get isLoansAddAmountLoading =>
      loansStatus == LoansStatus.addAmountLoading;

  bool get isLoansAddAmountSuccess =>
      loansStatus == LoansStatus.addAmountSuccess;
  bool get isLoansAddAmountError => loansStatus == LoansStatus.addAmountError;

  bool get isLoansElectronicTicketLoading =>
      loansStatus == LoansStatus.electronicTicketLoading;

  bool get isLoansElectronicTicketSuccess =>
      loansStatus == LoansStatus.electronicTicketSuccess;
  bool get isLoansElectronicTicketError =>
      loansStatus == LoansStatus.electronicTicketError;

  bool get isLoansDeleteLoading => loansStatus == LoansStatus.deleteLoanLoading;
  bool get isLoansDeleteSuccess => loansStatus == LoansStatus.deleteLoanSuccess;
  bool get isLoansDeleteError => loansStatus == LoansStatus.deleteLoanError;

  bool get isLoansSearchClientLoading =>
      loansSearchStatus == LoansStatus.searchClientLoading;
  bool get isLoansSearchClientError =>
      loansSearchStatus == LoansStatus.searchClientError;
  bool get isLoansSearchClientSuccess =>
      loansSearchStatus == LoansStatus.searchClientSuccess;

  bool get isLoansUpdateStatusLoading =>
      loansStatus == LoansStatus.updateStatusLoanLoading;
  bool get isLoansUpdateStatusError =>
      loansStatus == LoansStatus.updateStatusLoanError;
  bool get isLoansUpdateStatusSuccess =>
      loansStatus == LoansStatus.updateStatusLoanSuccess;

  bool get isLoansRenevLoading =>
      loansRenewStatus == LoansStatus.updateLoansLoading;
  bool get isLoansRenevError =>
      loansRenewStatus == LoansStatus.updateLoansError;
  bool get isLoansRenevSuccess =>
      loansRenewStatus == LoansStatus.updateLoansSuccess;

  bool get isSolicitudLoading => solicitudStatus == LoansStatus.loading;
  bool get isSolicitudError => solicitudStatus == LoansStatus.error;
  bool get isSolicitudSuccess => solicitudStatus == LoansStatus.loaded;

  bool get isAnexosLoading => anexosLoanStatus == AnexosLoanStatus.loading;
  bool get isAnexosError => anexosLoanStatus == AnexosLoanStatus.error;
  bool get isAnexosSuccess => anexosLoanStatus == AnexosLoanStatus.success;

  String fullNamesCustomerSunat() {
    return '${customerSunat?.nombre} ${customerSunat?.apellidoPaterno} ${customerSunat?.apellidoMaterno}';
  }

  String fullNames() {
    return '${customer?.nombres} ${customer?.apellidos}';
  }

  String formattedDate(String date) {
    final createdDate = DateTime.parse(date).toLocal();
    return DateFormat('dd/MM/yyyy - kk:mm').format(createdDate);
  }

  LoansState copyWith({
    bool? openBox,
    bool? typeSearch,
    String? searchText,
    LoansStatus? loansStatus,
    LoansStatus? loansSearchStatus,
    LoansStatus? loansRenewStatus,
    LoansStatus? solicitudStatus,
    AnexosLoanStatus? anexosLoanStatus,
    CustomerEntity? customer,
    CustomerEntity? searchCustomer,
    CustomerSunatEntity? customerSunat,
    LoansEntity? loanDetails,
    String? error,
    List<CategoriesEntity>? listCategories,
    int? cajaId,
    List<AnexoEntity>? listAnexos,
    AnexosLoanStatus? listAnexosStatus,
  }) =>
      LoansState(
        openBox: openBox,
        typeSearch: typeSearch ?? this.typeSearch,
        searchText: searchText ?? this.searchText,
        error: error ?? this.error,
        customer: customer ?? this.customer,
        searchCustomer: searchCustomer ?? this.searchCustomer,
        customerSunat: customerSunat ?? this.customerSunat,
        loansStatus: loansStatus ?? this.loansStatus,
        solicitudStatus: solicitudStatus ?? this.solicitudStatus,
        loansSearchStatus: loansSearchStatus ?? this.loansSearchStatus,
        loanDetails: loanDetails ?? this.loanDetails,
        listCategories: listCategories ?? this.listCategories,
        loansRenewStatus: loansRenewStatus ?? this.loansRenewStatus,
        cajaId: cajaId ?? this.cajaId,
        anexosLoanStatus: anexosLoanStatus ?? this.anexosLoanStatus,
        listAnexos: listAnexos ?? this.listAnexos,
        listAnexosStatus: listAnexosStatus ?? this.listAnexosStatus,
      );

  @override
  List<Object?> get props => [
        openBox,
        typeSearch,
        searchText,
        loansStatus,
        solicitudStatus,
        loansSearchStatus,
        customer,
        searchCustomer,
        customerSunat,
        error,
        loanDetails,
        listCategories,
        loansRenewStatus,
        cajaId,
        anexosLoanStatus,
        listAnexos,
        listAnexosStatus,
      ];
}
