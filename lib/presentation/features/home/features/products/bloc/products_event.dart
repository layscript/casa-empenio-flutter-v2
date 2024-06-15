part of 'products_bloc.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object> get props => [];
}

class LoadProducts extends ProductsEvent {
  final int offset;
  final String? search;
  final String? category;

  const LoadProducts({
    required this.offset,
    this.search,
    this.category,
  });

  @override
  List<Object> get props => [offset, search ?? '', category ?? ''];
}

class RefreshProducts extends ProductsEvent {
  final String? search;
  final String? category;

  const RefreshProducts({
    this.search,
    this.category,
  });

  @override
  List<Object> get props => [search ?? '', category ?? ''];
}
