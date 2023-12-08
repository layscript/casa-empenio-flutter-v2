import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({
    required ProductRepository productRepository,
    required CategoriesRepository categoriesRepository,
  })  : _productRepository = productRepository,
        _categoriesRepository = categoriesRepository,
        super(const ProductsState()) {
    on<GetProducts>(_onGetProducts);
    on<SearchProductsByName>(_onSearchProductsByName);
    on<SaveVehiculo>(_onSaveVehiculo);
    on<SaveProduct>(_onSaveProduct);
  }

  final ProductRepository _productRepository;
  final CategoriesRepository _categoriesRepository;

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
    final result = await Future.wait([
      _productRepository.getProducts(
        type: 0,
        criterio: '',
      ),
      _categoriesRepository.getCategories(),
    ]);
    final resultProducts = result[0] as Either<String, List<ProductEntity>>;
    final resultCategories =
        result[1] as Either<String, List<CategoriesEntity>>;

    resultCategories.fold(
      (error) => emit(
        state.copyWith(listCategories: []),
      ),
      (listCategories) => emit(
        state.copyWith(listCategories: listCategories),
      ),
    );

    resultProducts.fold(
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

  Future<void> _onSaveVehiculo(
    SaveVehiculo event,
    Emitter<ProductsState> emit,
  ) async {
    emit(_loadingState);
    bool result;
    if (event.id == null) {
      result = await _productRepository.createVehiculo(
        payload: {
          'descripcion': event.descripcion,
          'marca': event.marca,
          'modelo': event.modelo,
          'valorizacion': event.valorizacion,
          'observaciones': event.observaciones,
          'imagen': event.imagen,
          'imagen2': event.imagenDos,
          'cantidad': event.cantidad,
          'color': event.color,
          'serie': event.serie,
          'placa': event.placa,
          'anio': event.anio,
          'motor': event.motor,
          'carroceria': event.carroceria,
          'categoria': event.categoria,
        },
      );
    } else {
      result = await _productRepository.updateVehiculo(
        payload: {
          'id': event.id,
          'descripcion': event.descripcion,
          'marca': event.marca,
          'modelo': event.modelo,
          'valorizacion': event.valorizacion,
          'observaciones': event.observaciones,
          'imagen': event.imagen,
          'imagen2': event.imagenDos,
          'cantidad': event.cantidad,
          'color': event.color,
          'serie': event.serie,
          'placa': event.placa,
          'anio': event.anio,
          'motor': event.motor,
          'carroceria': event.carroceria,
          'categoria': event.categoria,
        },
      );
    }

    if (result) {
      emit(
        state.copyWith(
          productsStatus: ProductsStatus.success,
        ),
      );
    } else {
      emit(
        state.copyWith(
          productsStatus: ProductsStatus.failed,
        ),
      );
    }
  }

  Future<void> _onSaveProduct(
    SaveProduct event,
    Emitter<ProductsState> emit,
  ) async {
    /*  emit(_loadingState);
    await Future.delayed(Duration(seconds: 2));
    emit(
      state.copyWith(
        productsStatus: ProductsStatus.failed,
      ),
    ); */

    emit(_loadingState);
    bool? result;
    if (event.id == null) {
      result = await _productRepository.createProduct(
        payload: {
          'descripcion': event.descripcion,
          'marca': event.marca,
          'categoria': event.categoria,
          'placa': event.placa,
          'modelo': event.modelo,
          'valorizacion': event.valorizacion,
          'observaciones': event.observaciones,
          'imagen': event.imagen,
          'imagen2': event.imagenDos,
          'cantidad': event.cantidad,
        },
      );
    } else {
      result = await _productRepository.updateProduct(
        payload: {
          'id': event.id,
          'descripcion': event.descripcion,
          'marca': event.marca,
          'categoria': event.categoria,
          'placa': event.placa,
          'modelo': event.modelo,
          'valorizacion': event.valorizacion,
          'observaciones': event.observaciones,
          'imagen': event.imagen,
          'imagen2': event.imagenDos,
          'cantidad': event.cantidad,
        },
      );
    }

    if (result) {
      emit(
        state.copyWith(
          productsStatus: ProductsStatus.success,
        ),
      );
    } else {
      emit(
        state.copyWith(
          productsStatus: ProductsStatus.failed,
        ),
      );
    }
  }
}
