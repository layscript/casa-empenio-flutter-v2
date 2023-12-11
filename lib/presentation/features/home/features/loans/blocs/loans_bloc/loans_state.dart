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
}

class LoansState extends Equatable {
  const LoansState({
    this.searchText = '',
    this.openBox = false,
    this.typeSearch,
    this.loansStatus = LoansStatus.initial,
    this.loansSearchStatus = LoansStatus.initial,
    this.loansRenewStatus = LoansStatus.initial,
    this.customer,
    this.searchCustomer,
    this.customerSunat,
    this.error,
    this.loanDetails,
    this.listCategories,
  });

  final bool openBox;
  final bool? typeSearch;
  final String searchText;
  final LoansStatus loansStatus;
  final LoansStatus loansSearchStatus;
  final LoansStatus? loansRenewStatus;
  final CustomerEntity? customer;
  final CustomerEntity? searchCustomer;
  final CustomerSunatEntity? customerSunat;
  final String? error;
  final LoansEntity? loanDetails;
  final List<CategoriesEntity>? listCategories;

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

  bool get isLoansRenevLoading => loansRenewStatus == LoansStatus.loading;
  bool get isLoansRenevError => loansRenewStatus == LoansStatus.error;
  bool get isLoansRenevSuccess => loansRenewStatus == LoansStatus.loaded;

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
    CustomerEntity? customer,
    CustomerEntity? searchCustomer,
    CustomerSunatEntity? customerSunat,
    LoansEntity? loanDetails,
    String? error,
    List<CategoriesEntity>? listCategories,
  }) =>
      LoansState(
        openBox: openBox ?? this.openBox,
        typeSearch: typeSearch ?? this.typeSearch,
        searchText: searchText ?? this.searchText,
        error: error ?? this.error,
        customer: customer ?? this.customer,
        searchCustomer: searchCustomer ?? this.searchCustomer,
        customerSunat: customerSunat ?? this.customerSunat,
        loansStatus: loansStatus ?? this.loansStatus,
        loansSearchStatus: loansSearchStatus ?? this.loansSearchStatus,
        loanDetails: loanDetails ?? this.loanDetails,
        listCategories: listCategories ?? this.listCategories,
        loansRenewStatus: loansRenewStatus ?? this.loansRenewStatus,
      );

  @override
  List<Object?> get props => [
        openBox,
        typeSearch,
        searchText,
        loansStatus,
        loansSearchStatus,
        customer,
        searchCustomer,
        customerSunat,
        error,
        loanDetails,
        listCategories,
        loansRenewStatus,
      ];
}
