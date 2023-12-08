part of 'products_bloc.dart';

enum ProductsStatus { initial, loading, error, loaded, failed, success }

class ProductsState extends Equatable {
  const ProductsState({
    this.productsStatus = ProductsStatus.initial,
    this.listProducts,
    this.listCategories,
    this.error,
  });

  final ProductsStatus productsStatus;
  final List<ProductEntity>? listProducts;
  final List<CategoriesEntity>? listCategories;
  final String? error;

  bool get isProductLoading => productsStatus == ProductsStatus.loading;
  bool get isProductError => productsStatus == ProductsStatus.error;

  bool get isProductSuccess => productsStatus == ProductsStatus.success;
  bool get isProductFailure => productsStatus == ProductsStatus.failed;

  ProductsState copyWith({
    ProductsStatus? productsStatus,
    List<ProductEntity>? listProducts,
    List<CategoriesEntity>? listCategories,
    String? error,
  }) =>
      ProductsState(
        error: error ?? this.error,
        listProducts: listProducts ?? this.listProducts,
        listCategories: listCategories ?? this.listCategories,
        productsStatus: productsStatus ?? this.productsStatus,
      );

  @override
  List<Object?> get props => [
        productsStatus,
        listCategories,
        listProducts,
        error,
      ];
}
