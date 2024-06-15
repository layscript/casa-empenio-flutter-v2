import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductRepository _productRepository;
  final CategoriesRepository _categoriesRepository;

  ProductsBloc({
    required ProductRepository productRepository,
    required CategoriesRepository categoriesRepository,
  })  : _productRepository = productRepository,
        _categoriesRepository = categoriesRepository,
        super(ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<RefreshProducts>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductsState> emit,
  ) async {
    final currentState = state;
    List<ProductEntity> oldProducts = [];
    List<CategoriesEntity> categories = [];
    String? selectedSearch;
    CategoriesEntity? selectedCategory;
    bool isFirstFetch = event.offset == 0;

    if (currentState is ProductsLoaded) {
      oldProducts = currentState.products;
      categories = currentState.categories;
      selectedSearch = currentState.selectedSearch;
      selectedCategory = currentState.selectedCategory;
      isFirstFetch = currentState.isFirstFetch && event.offset == 0;
    }

    emit(
      ProductsLoading(
        oldProducts,
        categories,
        isFirstFetch: isFirstFetch,
        selectedSearch: selectedSearch,
        selectedCategory: selectedCategory,
      ),
    );

    try {
      final productsResult = await _productRepository.getProducts(
        type: 0,
        offset: event.offset,
        criterio: selectedSearch ?? '',
        categoria: selectedCategory?.descripcion ??
            '', // Mantener el filtro de categoría actual
      );

      final categoriesResult = await _categoriesRepository.getCategories();

      productsResult.fold(
        (error) => emit(ProductsError(error.toString())),
        (products) {
          categoriesResult.fold(
            (error) => emit(ProductsError(error.toString())),
            (categories) {
              final allProducts = oldProducts + products;
              emit(ProductsLoaded(
                products: allProducts,
                categories: categories,
                isFirstFetch: isFirstFetch,
                hasReachedMax: products.isEmpty,
                selectedSearch: selectedSearch,
                selectedCategory: selectedCategory,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading([], [], isFirstFetch: true));

    try {
      final productsResult = await _productRepository.getProducts(
        type: 0,
        offset: 0,
        criterio: event.search ?? '',
        categoria: event.category ?? '',
      );

      final categoriesResult = await _categoriesRepository.getCategories();

      productsResult.fold(
        (error) => emit(ProductsError(error.toString())),
        (products) {
          categoriesResult.fold(
            (error) => emit(ProductsError(error.toString())),
            (categories) {
              emit(ProductsLoaded(
                products: products,
                categories: categories,
                isFirstFetch: true,
                hasReachedMax: products.isEmpty,
                selectedSearch: event.search,
                selectedCategory: event.category != null
                    ? categories.firstWhere(
                        (element) => element.descripcion == event.category,
                        orElse: () => null!,
                      )
                    : null,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }
}
