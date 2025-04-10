part of 'sales_bloc.dart';

sealed class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object> get props => [];
}

class GetSalesInitial extends SalesEvent {}

class GetCashSalesStatus extends SalesEvent {}

class GetListSales extends SalesEvent {
  const GetListSales({
    required this.start,
    required this.end,
    required this.sucursalId,
  });

  final DateTime? start;
  final DateTime? end;
  final int sucursalId;
}

class GetCustomerSalesByDni extends SalesEvent {
  const GetCustomerSalesByDni(this.value);
  final String value;
}

class SaveProductSalesToCart extends SalesEvent {
  const SaveProductSalesToCart({
    required this.product,
    required this.precio,
    required this.observaciones,
    required this.cantidad,
  });
  final ProductEntity? product;
  final double precio;
  final String? observaciones;
  final int cantidad;
}

class UpdateProductSalesToCart extends SalesEvent {
  const UpdateProductSalesToCart({
    required this.id,
    required this.quantity,
  });

  final int id;
  final int quantity;
}

class DeleteProductSalesToCart extends SalesEvent {
  const DeleteProductSalesToCart({
    required this.id,
  });

  final int id;
}

class GenerateSalesProduct extends SalesEvent {
  const GenerateSalesProduct({required this.userId, required this.sucursalId});
  final int userId;
  final int sucursalId;
}

class UseGenericCustomer extends SalesEvent {
  const UseGenericCustomer();
}

class SetSalesManualCustomerData extends SalesEvent {
  const SetSalesManualCustomerData(this.customer);
  final CustomerSunatEntity customer;
}

class ResetSalesErrorState extends SalesEvent {
  const ResetSalesErrorState();
}

class UpdateProductPriceInCart extends SalesEvent {
  const UpdateProductPriceInCart({
    required this.id,
    required this.newPrice,
  });

  final int id;
  final double newPrice;
}

class UpdateProductObservationsInCart extends SalesEvent {
  const UpdateProductObservationsInCart({
    required this.id,
    required this.observations,
  });

  final int id;
  final String observations;
}

class UpdateProductDescriptionInCart extends SalesEvent {
  const UpdateProductDescriptionInCart({
    required this.id,
    required this.description,
  });

  final int id;
  final String description;
}
