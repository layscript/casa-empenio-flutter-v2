part of 'products_bloc.dart';

enum ProductsStatus { initial, loading, error, loaded, failed, success }

class ProductsState extends Equatable {
  const ProductsState({
    this.productsStatus = ProductsStatus.initial,
    this.listProducts,
    this.listCategories,
    this.error,
    this.offset = 0,
  });

  final ProductsStatus productsStatus;
  final List<ProductEntity>? listProducts;
  final List<CategoriesEntity>? listCategories;
  final String? error;
  final int offset;

  bool get isProductLoading => productsStatus == ProductsStatus.loading;
  bool get isProductError => productsStatus == ProductsStatus.error;

  bool get isProductSuccess => productsStatus == ProductsStatus.success;
  bool get isProductFailure => productsStatus == ProductsStatus.failed;

  ProductsState copyWith({
    ProductsStatus? productsStatus,
    List<ProductEntity>? listProducts,
    List<CategoriesEntity>? listCategories,
    String? error,
    int? offset,
  }) =>
      ProductsState(
        error: error ?? this.error,
        listProducts: listProducts ?? this.listProducts,
        listCategories: listCategories ?? this.listCategories,
        productsStatus: productsStatus ?? this.productsStatus,
        offset: offset ?? this.offset,
      );

  @override
  List<Object?> get props => [
        productsStatus,
        listCategories,
        listProducts,
        error,
        offset,
      ];
}
