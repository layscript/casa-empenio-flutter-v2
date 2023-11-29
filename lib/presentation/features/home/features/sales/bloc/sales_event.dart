part of 'sales_bloc.dart';

sealed class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object> get props => [];
}

class GetSalesInitial extends SalesEvent {}

class GetListSales extends SalesEvent {
  const GetListSales({
    required this.start,
    required this.end,
  });

  final DateTime? start;
  final DateTime? end;
}

class GetCustomerSalesByDni extends SalesEvent {
  const GetCustomerSalesByDni(this.value);
  final String value;
}

class SaveProductSalesToCart extends SalesEvent {
  const SaveProductSalesToCart({
    required this.product,
    required this.precio,
    required this.cantidad,
  });
  final ProductEntity? product;
  final double precio;
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
