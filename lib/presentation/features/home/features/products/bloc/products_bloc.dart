import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const ProductsState()) {
    on<GetProducts>(_onGetProducts);
    on<SearchProductsByName>(_onSearchProductsByName);
  }

  final ProductRepository _productRepository;

  ProductsState get _loadingState =>
      state.copyWith(productsStatus: ProductsStatus.loading);

  ProductsState _successState(List<ProductEntity> products) => state.copyWith(
        productsStatus: ProductsStatus.loaded,
        listProducts: products,
      );

  ProductsState _errorState(String message) => state.copyWith(
        productsStatus: ProductsStatus.error,
        error: message,
      );

  Future<void> _onGetProducts(
    GetProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(_loadingState);
    final result = await _productRepository.getProducts(
      type: 0,
      criterio: '',
    );
    result.fold(
      (message) {
        emit(_errorState(message));
      },
      (products) {
        emit(_successState(products));
      },
    );
  }

  Future<void> _onSearchProductsByName(
    SearchProductsByName event,
    Emitter<ProductsState> emit,
  ) async {
    emit(_loadingState);
    final result = await _productRepository.getProducts(
      type: 0,
      criterio: event.value,
    );
    result.fold(
      (message) {
        emit(_errorState(message));
      },
      (products) {
        emit(_successState(products));
      },
    );
  }
}
