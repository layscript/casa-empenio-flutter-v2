part of 'proforma_bloc.dart';

sealed class ProformaEvent extends Equatable {
  const ProformaEvent();

  @override
  List<Object> get props => [];
}

class GetProformasInitial extends ProformaEvent {}

class GetCashProformasStatus extends ProformaEvent {}

class GetListProformas extends ProformaEvent {
  const GetListProformas({
    required this.start,
    required this.end,
    required this.sucursalId,
  });

  final DateTime? start;
  final DateTime? end;
  final int sucursalId;
}

class GetCustomerProformasByDni extends ProformaEvent {
  const GetCustomerProformasByDni(this.value);
  final String value;
}

class SaveProductProformasToCart extends ProformaEvent {
  const SaveProductProformasToCart({
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

class UpdateProductProformasToCart extends ProformaEvent {
  const UpdateProductProformasToCart({
    required this.id,
    required this.quantity,
  });

  final int id;
  final int quantity;
}

class DeleteProductProformasToCart extends ProformaEvent {
  const DeleteProductProformasToCart({
    required this.id,
  });

  final int id;
}

class GenerateProformasProduct extends ProformaEvent {
  const GenerateProformasProduct(
      {required this.userId, required this.sucursalId});
  final int userId;
  final int sucursalId;
}

class SetManualCustomerData extends ProformaEvent {
  const SetManualCustomerData(this.customer);
  final CustomerSunatEntity customer;
}

class ProformaUpdateProductPriceInCart extends ProformaEvent {
  const ProformaUpdateProductPriceInCart({
    required this.id,
    required this.newPrice,
  });

  final int id;
  final double newPrice;
}

class ProformaUpdateProductObservationsInCart extends ProformaEvent {
  const ProformaUpdateProductObservationsInCart({
    required this.id,
    required this.observations,
  });

  final int id;
  final String observations;
}

class ProformaUpdateProductDescriptionInCart extends ProformaEvent {
  const ProformaUpdateProductDescriptionInCart({
    required this.id,
    required this.description,
  });

  final int id;
  final String description;
}
