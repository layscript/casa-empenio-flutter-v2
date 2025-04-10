import 'dart:async';
import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'sales_event.dart';
part 'sales_state.dart';

final _initialState = SalesState(
  status: SalesStatus.initial,
  addStatus: SalesStatus.initial,
  saveStatus: SalesStatus.initial,
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
    required CajaRepository cajaRepository,
    required Preferences preferences,
  })  : _preferences = preferences,
        _salesRepository = salesRepository,
        _customerRepository = customerRepository,
        _productRepository = productRepository,
        _cajaRepository = cajaRepository,
        super(_initialState) {
    on<GetSalesInitial>(
      (event, emit) => emit(
        state.copyWith(
          addStatus: SalesStatus.initial,
          customer: null,
        ),
      ),
    );

    on<GetListSales>(_onGetListSales);
    on<GetCashSalesStatus>(_onGetCashSalesStatus);
    on<GetCustomerSalesByDni>(_onGetCustomerSalesByDni);
    on<SaveProductSalesToCart>(_onSaveProductSalesToCart);
    on<DeleteProductSalesToCart>(_onDeleteProductSalesToCart);
    on<UpdateProductSalesToCart>(_onUpdateProductSalesToCart);
    on<UpdateProductPriceInCart>(_onUpdateProductPriceInCart);
    on<GenerateSalesProduct>(_onGenerateSalesProduct);
    on<UseGenericCustomer>(_onUseGenericCustomer);
    on<SetSalesManualCustomerData>(_onSetManualCustomerData);
    on<ResetSalesErrorState>(_onResetSalesErrorState);
  }

  final SalesRepository _salesRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;
  final CajaRepository _cajaRepository;
  final Preferences _preferences;

  Future<void> _onGetCashSalesStatus(
    GetCashSalesStatus event,
    Emitter<SalesState> emit,
  ) async {
    final result = await _cajaRepository.getCajaOfTheDay(
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
    );
    result.fold(
      // Error
      (left) => emit(
        state.copyWith(
          openBox: true,
        ),
      ),
      // Success
      (rigth) => emit(
        state.copyWith(
          openBox: rigth == null ? true : false,
        ),
      ),
    );
  }

  Future<void> _onGetListSales(
    GetListSales event,
    Emitter<SalesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SalesStatus.loading,
        startTimeSales: event.start ?? state.startTimeSales,
        endTimeSales: event.end ?? state.endTimeSales,
      ),
    );
    final result = await _salesRepository.getSalesByRangeDate(
      inicio: event.start ?? state.startTimeSales,
      fin: event.end ?? state.endTimeSales,
      sucursalId: event.sucursalId,
      userId: _preferences.token?.id ?? 1,
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
    emit(
      state.copyWith(
        addStatus: SalesStatus.loading,
        saveStatus: SalesStatus.initial,
        lastSearchedDocument: event.value,
      ),
    );

    final result = await _customerRepository.getCustomerSunatByDni(
      dni: event.value,
    );

    result.fold(
      (message) => emit(
        state.copyWith(
          addStatus: SalesStatus.error,
          lastSearchedDocument: event.value,
        ),
      ),
      (customer) => emit(
        state.copyWith(
          addStatus: SalesStatus.success,
          customer: customer,
          lastSearchedDocument: event.value,
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
      observaciones: event.observaciones,
    );

    if (state.selectedProductsSales == null) {
      final newProducts = [selectedProducts];
      emit(
        state.copyWith(
          customer: state.customer,
          selectedProductsSales: newProducts,
          // Restablecer el estado de error
          saveStatus: SalesStatus.initial,
          errorMessage: null,
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
          // Restablecer el estado de error
          saveStatus: SalesStatus.initial,
          errorMessage: null,
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
          // Restablecer el estado de error
          saveStatus: SalesStatus.initial,
          errorMessage: null,
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
          // Restablecer el estado de error
          saveStatus: SalesStatus.initial,
          errorMessage: null,
        ),
      );
    }
  }

  Future<void> _onGenerateSalesProduct(
    GenerateSalesProduct event,
    Emitter<SalesState> emit,
  ) async {
    if (state.isSaveSalesLoading == true) return;

    // Calcular el total de la venta
    List<Map<String, dynamic>> detalles = state.selectedProductsSales!.map((e) {
      final id = e.selectedProducts?.id.toString();

      if (id?.startsWith('2000') ?? false) {
        return {
          'cantidad': e.cantidad,
          'observaciones': e.observaciones,
          'precio': e.precio,
          'bienTemporal': e.selectedProducts?.descripcion,
          'bienGarantiaId': null,
          'gastoAdicional': 0,
        };
      } else {
        return {
          'cantidad': e.cantidad,
          'observaciones': e.observaciones,
          'precio': e.precio,
          'bienGarantiaId': e.selectedProducts?.id,
          'bienTemporal': null,
          'gastoAdicional': 0,
        };
      }
    }).toList();

    final total = detalles.fold(
        0.0,
        (previousValue, element) =>
            previousValue + (element['cantidad']! * element['precio']!));

    // Verificar si es cliente genérico (DNI = "00000000")
    final isGenericCustomer = state.customer?.dni == "00000000" ||
        (state.customer?.nombre == "Cliente Genérico" &&
                state.customer?.dni != null ||
            state.customer?.dni == "");

    // Validar monto máximo para cliente genérico (solo para boletas/DNI)
    if (isGenericCustomer && total > 700.0) {
      // Si el cliente es genérico y el monto es mayor a 700, mostrar error
      emit(
        state.copyWith(
          saveStatus: SalesStatus.error,
          errorMessage:
              "Para ventas mayores a S/. 700.00 debe usar un cliente con DNI real.",
          // Mantener los datos del cliente y productos
          customer: state.customer,
          selectedProductsSales: state.selectedProductsSales,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        saveStatus: SalesStatus.loading,
        customer: state.customer,
        selectedProductsSales: state.selectedProductsSales,
      ),
    );

    final data = <String, dynamic>{
      'detalleVentaDto': detalles,
      'total': total,
      'nombres': state.customer?.nombre,
      'apellidos':
          '${state.customer?.apellidoPaterno} ${state.customer?.apellidoMaterno}',
      'direccion': '${state.customer?.domicilio?.direccion}',
      'dni':
          '${state.customer?.customerDocument == '' ? '00000000' : state.customer?.customerDocument}',
      'usuarioId': event.userId,
      'sucursalId': event.sucursalId,
    };

    final result = await _salesRepository.createSalesProduct(data);
    if (result) {
      emit(
        state.copyWith(
          saveStatus: SalesStatus.success,
          customer: null,
          selectedProductsSales: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          saveStatus: SalesStatus.error,
          errorMessage: "Ocurrió un error al procesar la venta.",
          // Mantener los datos para que el usuario pueda intentar nuevamente
          customer: state.customer,
          selectedProductsSales: state.selectedProductsSales,
        ),
      );
    }
  }

  void _onUseGenericCustomer(
    UseGenericCustomer event,
    Emitter<SalesState> emit,
  ) {
    emit(
      state.copyWith(
        addStatus: SalesStatus.error,
        lastSearchedDocument: '',
      ),
    );
  }

  void _onSetManualCustomerData(
    SetSalesManualCustomerData event,
    Emitter<SalesState> emit,
  ) {
    emit(
      state.copyWith(
        addStatus: SalesStatus.success,
        customer: event.customer,
      ),
    );
  }

  void _onResetSalesErrorState(
    ResetSalesErrorState event,
    Emitter<SalesState> emit,
  ) {
    // Restablecer el estado de error pero mantener los datos del cliente y productos
    emit(
      state.copyWith(
        saveStatus: SalesStatus.initial,
        errorMessage: null,
        customer: state.customer,
        selectedProductsSales: state.selectedProductsSales,
      ),
    );
  }

  void _onUpdateProductPriceInCart(
    UpdateProductPriceInCart event,
    Emitter<SalesState> emit,
  ) {
    if (state.selectedProductsSales != null) {
      final updatedProducts = state.selectedProductsSales!.map(
        (e) {
          if (e.selectedProducts?.id == event.id) {
            return e.copyWith(precio: event.newPrice);
          } else {
            return e;
          }
        },
      ).toList();

      emit(
        state.copyWith(
          customer: state.customer,
          selectedProductsSales: updatedProducts,
          // Restablecer el estado de error
          saveStatus: SalesStatus.initial,
          errorMessage: null,
        ),
      );
    }
  }
}
