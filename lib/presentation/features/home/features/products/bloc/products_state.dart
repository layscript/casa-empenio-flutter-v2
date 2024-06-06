part of 'products_bloc.dart';

enum ProductsStatus { initial, loading, error, loaded, failed, success }

class ProductsState extends Equatable {
  const ProductsState({
    this.productsStatus = ProductsStatus.initial,
    this.listProducts,
    this.listCategories,
    this.error,
    this.offset = 0,
    this.categorySelected,
  });

  final ProductsStatus productsStatus;
  final List<ProductEntity>? listProducts;
  final List<CategoriesEntity>? listCategories;
  final String? error;
  final int offset;
  final CategoriesEntity? categorySelected;

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
    CategoriesEntity? categorySelected,
  }) =>
      ProductsState(
        error: error ?? this.error,
        listProducts: listProducts ?? this.listProducts,
        listCategories: listCategories ?? this.listCategories,
        productsStatus: productsStatus ?? this.productsStatus,
        offset: offset ?? this.offset,
        categorySelected: categorySelected,
      );

  @override
  List<Object?> get props => [
        productsStatus,
        listCategories,
        listProducts,
        error,
        offset,
        categorySelected,
      ];
}
