part of 'proforma_bloc.dart';

enum ProformaStatus {
  initial,
  loading,
  success,
  error,
}

class ProformaState extends Equatable {
  const ProformaState({
    this.openBox = false,
    required this.status,
    required this.addStatus,
    required this.saveStatus,
    required this.startTimeSales,
    required this.endTimeSales,
    required this.listSales,
    required this.totalSales,
    required this.customer,
    required this.selectedProductsSales,
  });

  final bool? openBox;
  final ProformaStatus status;
  final ProformaStatus addStatus;
  final ProformaStatus saveStatus;
  final DateTime startTimeSales;
  final DateTime endTimeSales;
  final List<SalesEntity> listSales;
  final double totalSales;

  final CustomerSunatEntity? customer;
  final List<ProductSales>? selectedProductsSales;

  bool get isSalesLoading => status == ProformaStatus.loading;
  bool get isSalesError => status == ProformaStatus.error;
  bool get isSalesSuccess => status == ProformaStatus.success;

  bool get isAddSalesLoading => addStatus == ProformaStatus.loading;
  bool get isAddSalesError => addStatus == ProformaStatus.error;
  bool get isAddSalesSuccess => addStatus == ProformaStatus.success;

  bool get isSaveSalesLoading => saveStatus == ProformaStatus.loading;
  bool get isSaveSalesError => saveStatus == ProformaStatus.error;
  bool get isSaveSalesSuccess => saveStatus == ProformaStatus.success;

  ProformaState copyWith({
    bool? openBox,
    ProformaStatus? status,
    ProformaStatus? addStatus,
    ProformaStatus? saveStatus,
    DateTime? startTimeSales,
    DateTime? endTimeSales,
    List<SalesEntity>? listSales,
    double? totalSales,
    CustomerSunatEntity? customer,
    List<ProductSales>? selectedProductsSales,
  }) =>
      ProformaState(
        openBox: openBox,
        status: status ?? this.status,
        addStatus: addStatus ?? this.addStatus,
        saveStatus: saveStatus ?? this.saveStatus,
        startTimeSales: startTimeSales ?? this.startTimeSales,
        endTimeSales: endTimeSales ?? this.endTimeSales,
        listSales: listSales ?? this.listSales,
        totalSales: totalSales ?? this.totalSales,
        customer: customer,
        selectedProductsSales: selectedProductsSales,
      );

  @override
  List<Object?> get props => [
        openBox,
        status,
        addStatus,
        saveStatus,
        startTimeSales,
        endTimeSales,
        listSales,
        totalSales,
        customer,
        selectedProductsSales,
      ];
}
