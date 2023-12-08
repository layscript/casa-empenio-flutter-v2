part of 'categories_bloc.dart';

sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object> get props => [];
}

class GetCategories extends CategoriesEvent {}

class SaveCategories extends CategoriesEvent {
  const SaveCategories({required this.data});
  final String data;
}

class UpdateCategories extends CategoriesEvent {
  const UpdateCategories({required this.id, required this.data});
  final String data;
  final int id;
}

class DeleteCategories extends CategoriesEvent {
  const DeleteCategories({required this.id});
  final int id;
}
