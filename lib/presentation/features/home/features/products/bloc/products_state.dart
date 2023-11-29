part of 'products_bloc.dart';

enum ProductsStatus { initial, loading, error, loaded }

class ProductsState extends Equatable {
  const ProductsState({
    this.productsStatus = ProductsStatus.initial,
    this.listProducts,
    this.error,
  });

  final ProductsStatus productsStatus;
  final List<ProductEntity>? listProducts;
  final String? error;

  bool get isProductLoading => productsStatus == ProductsStatus.loading;
  bool get isProductError => productsStatus == ProductsStatus.error;

  ProductsState copyWith({
    ProductsStatus? productsStatus,
    List<ProductEntity>? listProducts,
    String? error,
  }) =>
      ProductsState(
        error: error ?? this.error,
        listProducts: listProducts ?? this.listProducts,
        productsStatus: productsStatus ?? this.productsStatus,
      );

  @override
  List<Object?> get props => [
        productsStatus,
        listProducts,
        error,
      ];
}
