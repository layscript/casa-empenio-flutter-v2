part of 'reports_bloc.dart';

enum ReportsStatus { initial, loading, success, error }

enum ReportsContractsStatus { initial, loading, success, error }

class ReportsState extends Equatable {
  const ReportsState({
    required this.statusClosedLoans,
    required this.statusPayments,
    required this.statusIncreases,
    required this.statusLoans,
    required this.startTimePayments,
    required this.endTimePayments,
    required this.startTimeContracts,
    required this.endTimeContracts,
    required this.listClosedLoans,
    required this.listPayments,
    required this.totalPayments,
    required this.partialUtilityPayment,
    required this.fullPaymentUtility,
    required this.totalClosedLoans,
    required this.listLoans,
    required this.totalIncreases,
    required this.totalProfits,
    required this.realBenefit,
    required this.theoreticalProfit,
    required this.totalLoans,
    required this.listIncrease,
    required this.canceladoContracts,
    required this.liquidadoContracts,
    required this.pagadoContracts,
    required this.vencidoContracts,
    required this.ventaContracts,
    required this.vigentContracts,
    required this.loanDetails,
    required this.statusDetails,
    required this.statusCanceled,
    required this.paymentDetails,
    required this.message,
    required this.listCategories,
    required this.selectedCategory,
    required this.statusCanceledContracts,
    required this.statusDeudas,
    required this.listDeudas,
  });

  final ReportsStatus statusClosedLoans;
  final ReportsStatus statusPayments;
  final ReportsStatus statusIncreases;
  final ReportsStatus statusLoans;
  final ReportsStatus statusDetails;
  final ReportsStatus statusCanceled;
  final ReportsStatus statusDeudas;
  final ReportsContractsStatus statusCanceledContracts;

  final DateTime startTimePayments;
  final DateTime endTimePayments;
  final List<LoansEntity> listClosedLoans;
  final List<LoansEntity> listLoans;
  final List<ReportsPaymentEntity> listPayments;
  final List<LoansEntity>? listDeudas;
  final double totalPayments;

  final double partialUtilityPayment;
  final double fullPaymentUtility;

  final double totalClosedLoans;
  final double totalIncreases;
  final double totalLoans;

  final double totalProfits;
  final double realBenefit;
  final double theoreticalProfit;

  final List<ReportsContractsEntity> listIncrease;
  final LoansEntity? loanDetails;
  final ReportsPaymentEntity? paymentDetails;

  final DateTime startTimeContracts;
  final DateTime endTimeContracts;

  final bool vigentContracts;
  final bool vencidoContracts;
  final bool pagadoContracts;
  final bool ventaContracts;
  final bool liquidadoContracts;
  final bool canceladoContracts;
  final String? message;

  final List<CategoriesEntity> listCategories;
  final CategoriesEntity? selectedCategory;

  bool get isReportsClosedLoansLoading =>
      statusClosedLoans == ReportsStatus.loading;
  bool get isReportsClosedLoansError =>
      statusClosedLoans == ReportsStatus.error;
  bool get isReportsClosedLoansSuccess =>
      statusClosedLoans == ReportsStatus.success;

  bool get isReportsPaymentsLoading => statusPayments == ReportsStatus.loading;
  bool get isReportsPaymentsError => statusPayments == ReportsStatus.error;
  bool get isReportsPaymentsSuccess => statusPayments == ReportsStatus.success;

  bool get isReportsIncreasesLoading =>
      statusIncreases == ReportsStatus.loading;
  bool get isReportsIncreasesError => statusIncreases == ReportsStatus.error;
  bool get isReportsIncreasesSuccess =>
      statusIncreases == ReportsStatus.success;

  bool get isReportsLoansLoading => statusLoans == ReportsStatus.loading;
  bool get isReportsLoansError => statusLoans == ReportsStatus.error;
  bool get isReportsLoansSuccess => statusLoans == ReportsStatus.success;

  bool get isReportsDetailsLoading => statusDetails == ReportsStatus.loading;
  bool get isReportsDetailsError => statusDetails == ReportsStatus.error;
  bool get isReportsDetailsSuccess => statusDetails == ReportsStatus.success;

  bool get isReportsCanceledLoading => statusCanceled == ReportsStatus.loading;
  bool get isReportsCanceledError => statusCanceled == ReportsStatus.error;
  bool get isReportsCanceledSuccess => statusCanceled == ReportsStatus.success;

  bool get isReportsContractCanceledLoading =>
      statusCanceledContracts == ReportsContractsStatus.loading;

  bool get isReportsContractCanceledError =>
      statusCanceledContracts == ReportsContractsStatus.error;

  bool get isReportsContractCanceledSuccess =>
      statusCanceledContracts == ReportsContractsStatus.success;

  ReportsState copyWith({
    ReportsStatus? statusIncreases,
    ReportsStatus? statusLoans,
    ReportsStatus? statusClosedLoans,
    ReportsStatus? statusPayments,
    ReportsStatus? statusDetails,
    ReportsStatus? statusCanceled,
    ReportsStatus? statusDeudas,
    DateTime? startTimePayments,
    DateTime? endTimePayments,
    List<LoansEntity>? listClosedLoans,
    List<LoansEntity>? listLoans,
    List<ReportsContractsEntity>? listIncrease,
    List<ReportsPaymentEntity>? listPayments,
    List<LoansEntity>? listDeudas,
    DateTime? startTimeContracts,
    DateTime? endTimeContracts,
    double? totalPayments,
    double? partialUtilityPayment,
    double? fullPaymentUtility,
    double? totalClosedLoans,
    double? totalIncreases,
    double? totalProfits,
    double? totalLoans,
    double? realBenefit,
    double? theoreticalProfit,
    bool? vigentContracts,
    bool? vencidoContracts,
    bool? pagadoContracts,
    bool? ventaContracts,
    bool? liquidadoContracts,
    bool? canceladoContracts,
    LoansEntity? loanDetails,
    ReportsPaymentEntity? paymentDetails,
    String? message,
    List<CategoriesEntity>? listCategories,
    CategoriesEntity? selectedCategory,
    ReportsContractsStatus? statusCanceledContracts,
  }) =>
      ReportsState(
        statusCanceled: statusCanceled ?? this.statusCanceled,
        statusIncreases: statusIncreases ?? this.statusIncreases,
        statusLoans: statusLoans ?? this.statusLoans,
        statusClosedLoans: statusClosedLoans ?? this.statusClosedLoans,
        statusDetails: statusDetails ?? this.statusDetails,
        statusPayments: statusPayments ?? this.statusPayments,
        startTimePayments: startTimePayments ?? this.startTimePayments,
        endTimePayments: endTimePayments ?? this.endTimePayments,
        startTimeContracts: startTimeContracts ?? this.startTimeContracts,
        endTimeContracts: endTimeContracts ?? this.endTimeContracts,
        listClosedLoans: listClosedLoans ?? this.listClosedLoans,
        listPayments: listPayments ?? this.listPayments,
        totalPayments: totalPayments ?? this.totalPayments,
        partialUtilityPayment:
            partialUtilityPayment ?? this.partialUtilityPayment,
        fullPaymentUtility: fullPaymentUtility ?? this.fullPaymentUtility,
        totalClosedLoans: totalClosedLoans ?? this.totalClosedLoans,
        listLoans: listLoans ?? this.listLoans,
        totalIncreases: totalIncreases ?? this.totalIncreases,
        totalProfits: totalProfits ?? this.totalProfits,
        realBenefit: realBenefit ?? this.realBenefit,
        theoreticalProfit: theoreticalProfit ?? this.theoreticalProfit,
        totalLoans: totalLoans ?? this.totalLoans,
        listIncrease: listIncrease ?? this.listIncrease,
        vigentContracts: vigentContracts ?? this.vigentContracts,
        vencidoContracts: vencidoContracts ?? this.vencidoContracts,
        pagadoContracts: pagadoContracts ?? this.pagadoContracts,
        ventaContracts: ventaContracts ?? this.ventaContracts,
        liquidadoContracts: liquidadoContracts ?? this.liquidadoContracts,
        canceladoContracts: canceladoContracts ?? this.canceladoContracts,
        loanDetails: loanDetails ?? this.loanDetails,
        paymentDetails: paymentDetails ?? this.paymentDetails,
        message: message ?? this.message,
        listCategories: listCategories ?? this.listCategories,
        selectedCategory: selectedCategory,
        statusCanceledContracts:
            statusCanceledContracts ?? this.statusCanceledContracts,
        statusDeudas: statusDeudas ?? this.statusDeudas,
        listDeudas: listDeudas ?? this.listDeudas,
      );

  @override
  List<Object?> get props => [
        statusCanceled,
        statusLoans,
        statusIncreases,
        statusClosedLoans,
        statusPayments,
        statusDetails,
        startTimePayments,
        endTimePayments,
        listClosedLoans,
        startTimeContracts,
        endTimeContracts,
        listPayments,
        totalPayments,
        partialUtilityPayment,
        fullPaymentUtility,
        totalClosedLoans,
        listLoans,
        totalProfits,
        realBenefit,
        theoreticalProfit,
        totalIncreases,
        totalLoans,
        listIncrease,
        vigentContracts,
        vencidoContracts,
        pagadoContracts,
        ventaContracts,
        liquidadoContracts,
        canceladoContracts,
        loanDetails,
        paymentDetails,
        message,
        listCategories,
        selectedCategory,
        statusCanceledContracts,
        statusDeudas,
        listDeudas,
      ];
}
