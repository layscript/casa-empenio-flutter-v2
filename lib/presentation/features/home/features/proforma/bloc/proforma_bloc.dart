import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:equatable/equatable.dart';

part 'proforma_event.dart';
part 'proforma_state.dart';

final _initialState = ProformaState(
  status: ProformaStatus.initial,
  addStatus: ProformaStatus.initial,
  saveStatus: ProformaStatus.initial,
  startTimeSales: DateTime.now(),
  endTimeSales: DateTime.now(),
  listSales: const [],
  totalSales: 0.0,
  customer: null,
  selectedProductsSales: null,
);

class ProformaBloc extends Bloc<ProformaEvent, ProformaState> {
  ProformaBloc({
    required ProformaRepository proformaRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
    required CajaRepository cajaRepository,
    required Preferences preferences,
  })  : _preferences = preferences,
        _proformaRepository = proformaRepository,
        _customerRepository = customerRepository,
        _cajaRepository = cajaRepository,
        super(_initialState) {
    on<GetProformasInitial>(
      (event, emit) => emit(
        state.copyWith(
          addStatus: ProformaStatus.initial,
          customer: null,
        ),
      ),
    );

    on<GetListProformas>(_onGetListProformas);
    on<GetCashProformasStatus>(_onGetCashProformasStatus);
    on<GetCustomerProformasByDni>(_onGetCustomerProformasByDni);
    on<SaveProductProformasToCart>(_onSaveProductProformasToCart);
    on<DeleteProductProformasToCart>(_onDeleteProductProformasToCart);
    on<UpdateProductProformasToCart>(_onUpdateProductProformasToCart);
    on<GenerateProformasProduct>(_onGenerateProformasProduct);
  }

  final ProformaRepository _proformaRepository;
  final CustomerRepository _customerRepository;
  final CajaRepository _cajaRepository;
  final Preferences _preferences;

  Future<void> _onGetCashProformasStatus(
    GetCashProformasStatus event,
    Emitter<ProformaState> emit,
  ) async {
    final result = await _cajaRepository.getCajaOfTheDay();
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

  Future<void> _onGetListProformas(
    GetListProformas event,
    Emitter<ProformaState> emit,
  ) async {
    emit(state.copyWith(status: ProformaStatus.loading));
    final result = await _proformaRepository.getProformasByRangeDate(
      inicio: event.start ?? state.startTimeSales,
      fin: event.end ?? state.endTimeSales,
      sucursalId: event.sucursalId,
      userId: _preferences.token?.id ?? 1,
    );
    result.fold(
      (message) => emit(
        state.copyWith(
          status: ProformaStatus.error,
        ),
      ),
      (listSales) {
        final total = listSales.fold(
            0.0,
            (previousValue, element) =>
                previousValue + double.parse(element.total.toString()));

        emit(
          state.copyWith(
            status: ProformaStatus.success,
            listSales: listSales,
            totalSales: total,
          ),
        );
      },
    );
  }

  Future<void> _onGetCustomerProformasByDni(
    GetCustomerProformasByDni event,
    Emitter<ProformaState> emit,
  ) async {
    emit(
      state.copyWith(
        addStatus: ProformaStatus.loading,
        saveStatus: ProformaStatus.initial,
      ),
    );

    final result = await _customerRepository.getCustomerSunatByDni(
      dni: event.value,
    );

    result.fold(
      (message) => emit(
        state.copyWith(
          addStatus: ProformaStatus.error,
        ),
      ),
      (customer) => emit(
        state.copyWith(
          addStatus: ProformaStatus.success,
          customer: customer,
        ),
      ),
    );
  }

  void _onSaveProductProformasToCart(
    SaveProductProformasToCart event,
    Emitter<ProformaState> emit,
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

  void _onDeleteProductProformasToCart(
    DeleteProductProformasToCart event,
    Emitter<ProformaState> emit,
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

  void _onUpdateProductProformasToCart(
    UpdateProductProformasToCart event,
    Emitter<ProformaState> emit,
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

  Future<void> _onGenerateProformasProduct(
    GenerateProformasProduct event,
    Emitter<ProformaState> emit,
  ) async {
    if (state.isSaveSalesLoading == true) return;
    emit(
      state.copyWith(
        saveStatus: ProformaStatus.loading,
        customer: state.customer,
        selectedProductsSales: state.selectedProductsSales,
      ),
    );

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

    final data = <String, dynamic>{
      'detalleProformaDto': detalles,
      'total': detalles.fold(
          0.0,
          (previousValue, element) =>
              previousValue + (element['cantidad']! * element['precio']!)),
      'nombres': state.customer?.nombre,
      'apellidos':
          '${state.customer?.apellidoPaterno} ${state.customer?.apellidoMaterno}',
      'direccion': '${state.customer?.domicilio?.direccion}',
      'dni': '${state.customer?.dni}',
      'usuarioId': event.userId,
      'sucursalId': event.sucursalId,
    };

    final result = await _proformaRepository.createProformasProduct(data);
    if (result) {
      emit(
        state.copyWith(
          saveStatus: ProformaStatus.success,
          customer: null,
          selectedProductsSales: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          saveStatus: ProformaStatus.error,
          customer: null,
          selectedProductsSales: null,
        ),
      );
    }
  }
}
