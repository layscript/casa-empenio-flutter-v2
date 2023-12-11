part of 'sales_bloc.dart';

enum SalesStatus {
  initial,
  loading,
  success,
  error,
}

class ProductSales {
  const ProductSales({
    required this.selectedProducts,
    required this.precio,
    required this.cantidad,
    required this.gastoAdicional,
    required this.observaciones,
  });

  final ProductEntity? selectedProducts;
  final double precio;
  final double? gastoAdicional;
  final String? observaciones;
  final int cantidad;

  ProductSales copyWith({
    ProductEntity? selectedProducts,
    double? precio,
    int? cantidad,
    double? gastoAdicional,
    String? observaciones,
  }) =>
      ProductSales(
        selectedProducts: selectedProducts ?? this.selectedProducts,
        precio: precio ?? this.precio,
        cantidad: cantidad ?? this.cantidad,
        gastoAdicional: gastoAdicional ?? this.gastoAdicional,
        observaciones: observaciones ?? this.observaciones,
      );
}

class SalesState extends Equatable {
  const SalesState({
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

  final bool openBox;
  final SalesStatus status;
  final SalesStatus addStatus;
  final SalesStatus saveStatus;
  final DateTime startTimeSales;
  final DateTime endTimeSales;
  final List<SalesEntity> listSales;
  final double totalSales;

  final CustomerSunatEntity? customer;
  final List<ProductSales>? selectedProductsSales;

  bool get isSalesLoading => status == SalesStatus.loading;
  bool get isSalesError => status == SalesStatus.error;
  bool get isSalesSuccess => status == SalesStatus.success;

  bool get isAddSalesLoading => addStatus == SalesStatus.loading;
  bool get isAddSalesError => addStatus == SalesStatus.error;
  bool get isAddSalesSuccess => addStatus == SalesStatus.success;

  bool get isSaveSalesLoading => saveStatus == SalesStatus.loading;
  bool get isSaveSalesError => saveStatus == SalesStatus.error;
  bool get isSaveSalesSuccess => saveStatus == SalesStatus.success;

  SalesState copyWith({
    bool? openBox,
    SalesStatus? status,
    SalesStatus? addStatus,
    SalesStatus? saveStatus,
    DateTime? startTimeSales,
    DateTime? endTimeSales,
    List<SalesEntity>? listSales,
    double? totalSales,
    CustomerSunatEntity? customer,
    List<ProductSales>? selectedProductsSales,
  }) =>
      SalesState(
        openBox: openBox ?? this.openBox,
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
