import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(ProductsInitial()) {
    on<GetProducts>(_onGetProducts);
  }

  final ProductRepository _productRepository;

  Future<void> _onGetProducts(
    GetProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    final result = await _productRepository.getProducts(
      type: 0,
      criterio: '',
    );
    result.fold(
      (message) {
        emit(ProductsError(message));
      },
      (products) {
        emit(ProductsLoaded(products));
      },
    );
  }
}
