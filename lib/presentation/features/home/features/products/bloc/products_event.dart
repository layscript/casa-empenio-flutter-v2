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
