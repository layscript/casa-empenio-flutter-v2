part of 'sales_bloc.dart';

enum SalesStatus { initial, loading, success, error }

class ProductSales {
  const ProductSales({
    required this.selectedProducts,
    required this.precio,
    required this.cantidad,
  });

  final ProductEntity? selectedProducts;
  final double precio;
  final int cantidad;

  ProductSales copyWith({
    ProductEntity? selectedProducts,
    double? precio,
    int? cantidad,
  }) =>
      ProductSales(
        selectedProducts: selectedProducts ?? this.selectedProducts,
        precio: precio ?? this.precio,
        cantidad: cantidad ?? this.cantidad,
      );
}

class SalesState extends Equatable {
  const SalesState({
    required this.status,
    required this.addStatus,
    required this.startTimeSales,
    required this.endTimeSales,
    required this.listSales,
    required this.totalSales,
    required this.customer,
    required this.selectedProductsSales,
  });

  final SalesStatus status;
  final SalesStatus addStatus;
  final DateTime startTimeSales;
  final DateTime endTimeSales;
  final List<SalesEntity> listSales;
  final double totalSales;

  final CustomerSunatEntity? customer;
  final List<ProductSales>? selectedProductsSales;

  bool get isSalesLoading => status == SalesStatus.loading;
  bool get isSalesError => status == SalesStatus.error;
  bool get isSalesSuccess => status == SalesStatus.success;

  bool get isAddSalesLoading => status == SalesStatus.loading;
  bool get isAddSalesError => status == SalesStatus.error;
  bool get isAddSalesSuccess => status == SalesStatus.success;

  SalesState copyWith({
    SalesStatus? status,
    SalesStatus? addStatus,
    DateTime? startTimeSales,
    DateTime? endTimeSales,
    List<SalesEntity>? listSales,
    double? totalSales,
    CustomerSunatEntity? customer,
    List<ProductSales>? selectedProductsSales,
  }) =>
      SalesState(
        status: status ?? this.status,
        addStatus: addStatus ?? this.addStatus,
        startTimeSales: startTimeSales ?? this.startTimeSales,
        endTimeSales: endTimeSales ?? this.endTimeSales,
        listSales: listSales ?? this.listSales,
        totalSales: totalSales ?? this.totalSales,
        customer: customer,
        selectedProductsSales:
            selectedProductsSales ?? this.selectedProductsSales,
      );

  @override
  List<Object?> get props => [
        status,
        addStatus,
        startTimeSales,
        endTimeSales,
        listSales,
        totalSales,
        customer,
        selectedProductsSales,
      ];
}
