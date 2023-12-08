part of 'products_bloc.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object> get props => [];
}

class GetProducts extends ProductsEvent {}

class SearchProductsByName extends ProductsEvent {
  const SearchProductsByName({
    required this.value,
  });
  final String value;
}

class SaveProduct extends ProductsEvent {
  const SaveProduct({
    required this.id,
    required this.descripcion,
    required this.categoria,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.valorizacion,
    required this.observaciones,
    required this.imagen,
    required this.imagenDos,
    //required this.imagenTres,
    required this.cantidad,
  });

  final int? id;
  final String? descripcion;
  final String? categoria;
  final String? placa;
  final String? marca;
  final String? modelo;
  final double? valorizacion;
  final String? observaciones;
  final String? imagen;
  final String? imagenDos;
  //final String? imagenTres;
  final int? cantidad;
}

class SaveVehiculo extends ProductsEvent {
  const SaveVehiculo({
    required this.id,
    required this.descripcion,
    required this.categoria,
    required this.marca,
    required this.modelo,
    required this.valorizacion,
    required this.observaciones,
    required this.imagen,
    required this.imagenDos,
    required this.cantidad,
    required this.color,
    required this.serie,
    required this.placa,
    required this.anio,
    required this.motor,
    required this.carroceria,
  });

  final int? id;
  final String? descripcion;
  final String? categoria;
  final String? marca;
  final String? modelo;
  final double? valorizacion;
  final String? observaciones;
  final String? imagen;
  final String? imagenDos;
  final int? cantidad;
  final String? color;
  final String? serie;
  final String? placa;
  final String? anio;
  final String? motor;
  final String? carroceria;
}

/* class GetInterests extends InterestsEvent {}

class SaveInterest extends InterestsEvent {
  const SaveInterest({required this.data});
  final String data;
}

class UpdateInterest extends InterestsEvent {
  const UpdateInterest({required this.id, required this.data});
  final String data;
  final int id;
}

class DeleteInterest extends InterestsEvent {
  const DeleteInterest({required this.id});
  final int id;
} */
