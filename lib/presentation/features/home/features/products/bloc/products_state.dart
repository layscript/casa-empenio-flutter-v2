part of 'products_bloc.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {
  final List<ProductEntity> products;
  final List<CategoriesEntity> categories;
  final bool isFirstFetch;
  final String? selectedSearch;
  final CategoriesEntity? selectedCategory;

  const ProductsLoading(
    this.products,
    this.categories, {
    this.isFirstFetch = false,
    this.selectedSearch,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [
        products,
        categories,
        isFirstFetch,
        selectedSearch,
        selectedCategory,
      ];
}

class ProductsLoaded extends ProductsState {
  final List<ProductEntity> products;
  final List<CategoriesEntity> categories;
  final bool isFirstFetch;
  final bool hasReachedMax;
  final String? selectedSearch;
  final CategoriesEntity? selectedCategory;

  const ProductsLoaded({
    required this.products,
    required this.categories,
    required this.isFirstFetch,
    required this.hasReachedMax,
    this.selectedSearch,
    this.selectedCategory,
  });

  @override
  List<Object> get props => [
        products,
        categories,
        isFirstFetch,
        hasReachedMax,
        selectedSearch ?? '',
        selectedCategory ?? ''
      ];
}

class ProductsError extends ProductsState {
  final String error;

  const ProductsError(this.error);

  @override
  List<Object> get props => [error];
}
