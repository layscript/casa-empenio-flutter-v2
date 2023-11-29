import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'sales_event.dart';
part 'sales_state.dart';

final _initialState = SalesState(
  status: SalesStatus.initial,
  addStatus: SalesStatus.initial,
  startTimeSales: DateTime.now(),
  endTimeSales: DateTime.now(),
  listSales: const [],
  totalSales: 0.0,
  customer: null,
  selectedProductsSales: null,
);

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  SalesBloc({
    required SalesRepository salesRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
  })  : _salesRepository = salesRepository,
        _customerRepository = customerRepository,
        _productRepository = productRepository,
        super(_initialState) {
    on<GetSalesInitial>((event, emit) => emit(
          state.copyWith(
            addStatus: SalesStatus.initial,
            customer: null,
          ),
        ));
    on<GetListSales>(_onGetListSales);
    on<GetCustomerSalesByDni>(_onGetCustomerSalesByDni);
    on<SaveProductSalesToCart>(_onSaveProductSalesToCart);
    on<DeleteProductSalesToCart>(_onDeleteProductSalesToCart);
    on<UpdateProductSalesToCart>(_onUpdateProductSalesToCart);
  }

  final SalesRepository _salesRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;

  Future<void> _onGetListSales(
    GetListSales event,
    Emitter<SalesState> emit,
  ) async {
    emit(state.copyWith(status: SalesStatus.loading));
    final result = await _salesRepository.getSalesByRangeDate(
      inicio: event.start ?? state.startTimeSales,
      fin: event.end ?? state.endTimeSales,
    );
    result.fold(
      (message) => emit(
        state.copyWith(
          status: SalesStatus.error,
        ),
      ),
      (listSales) {
        final total = listSales.fold(
            0.0,
            (previousValue, element) =>
                previousValue + double.parse(element.total.toString()));

        emit(
          state.copyWith(
            status: SalesStatus.success,
            listSales: listSales,
            totalSales: total,
          ),
        );
      },
    );
  }

  Future<void> _onGetCustomerSalesByDni(
    GetCustomerSalesByDni event,
    Emitter<SalesState> emit,
  ) async {
    emit(state.copyWith(addStatus: SalesStatus.loading));

    final result = await _customerRepository.getCustomerSunatByDni(
      dni: event.value,
    );

    result.fold(
      (message) => emit(
        state.copyWith(
          addStatus: SalesStatus.error,
        ),
      ),
      (customer) => emit(
        state.copyWith(
          addStatus: SalesStatus.success,
          customer: customer,
        ),
      ),
    );
  }

  void _onSaveProductSalesToCart(
    SaveProductSalesToCart event,
    Emitter<SalesState> emit,
  ) {
    final selectedProducts = ProductSales(
      selectedProducts: event.product,
      precio: event.precio,
      cantidad: event.cantidad,
    );

    if (state.selectedProductsSales == null) {
      final newProducts = [selectedProducts];
      emit(
        state.copyWith(
          customer: state.customer,
          selectedProductsSales: newProducts,
        ),
      );
    } else {
      final newProducts = [
        ...state.selectedProductsSales!,
        selectedProducts,
      ];
      emit(
        state.copyWith(
          customer: state.customer,
          selectedProductsSales: newProducts,
        ),
      );
    }
  }

  void _onDeleteProductSalesToCart(
    DeleteProductSalesToCart event,
    Emitter<SalesState> emit,
  ) {
    if (state.selectedProductsSales != null) {
      final filterProduct = state.selectedProductsSales!
          .where(
            (element) => element.selectedProducts?.id != event.id,
          )
          .toList();

      emit(
        state.copyWith(
          customer: state.customer,
          selectedProductsSales: filterProduct,
        ),
      );
    }
  }

  void _onUpdateProductSalesToCart(
    UpdateProductSalesToCart event,
    Emitter<SalesState> emit,
  ) {
    if (state.selectedProductsSales != null) {
      final filterProduct = state.selectedProductsSales!.map(
        (e) {
          if (e.selectedProducts?.id == event.id) {
            return e.copyWith(cantidad: event.quantity);
          } else {
            return e;
          }
        },
      ).toList();
      emit(
        state.copyWith(
          customer: state.customer,
          selectedProductsSales: filterProduct,
        ),
      );
    }
  }
}
