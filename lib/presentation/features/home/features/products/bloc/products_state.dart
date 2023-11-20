part of 'products_bloc.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object> get props => [];
}

final class ProductsInitial extends ProductsState {}

final class ProductsLoading extends ProductsState {}

final class ProductsLoaded extends ProductsState {
  const ProductsLoaded(this.listProducts);
  final List<Product> listProducts;
}

final class ProductsError extends ProductsState {
  const ProductsError(this.message);
  final String message;
}

/* final class InterestsInitial extends InterestsState {}

final class InterestsLoading extends InterestsState {}

final class InterestsLoaded extends InterestsState {
  const InterestsLoaded(this.listInterests);
  final List<Interests> listInterests;
}

final class InterestsError extends InterestsState {
  const InterestsError(this.message);
  final String message;
} */
