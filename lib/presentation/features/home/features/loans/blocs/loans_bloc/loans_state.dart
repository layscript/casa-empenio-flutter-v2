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

  ///
  loadingDetailsLoan,
  loadingDetailsSunat,
}

class LoansState extends Equatable {
  const LoansState({
    this.loansStatus = LoansStatus.initial,
    this.customer,
    this.customerSunat,
    this.error,
    this.loanDetails,
  });

  final LoansStatus loansStatus;
  final CustomerEntity? customer;
  final CustomerSunatEntity? customerSunat;
  final String? error;
  final LoansEntity? loanDetails;

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
    LoansStatus? loansStatus,
    CustomerEntity? customer,
    CustomerSunatEntity? customerSunat,
    LoansEntity? loanDetails,
    String? error,
  }) =>
      LoansState(
        error: error ?? this.error,
        customer: customer ?? this.customer,
        customerSunat: customerSunat ?? this.customerSunat,
        loansStatus: loansStatus ?? this.loansStatus,
        loanDetails: loanDetails ?? this.loanDetails,
      );

  @override
  List<Object?> get props => [
        loansStatus,
        customer,
        customerSunat,
        error,
        loanDetails,
      ];
}
