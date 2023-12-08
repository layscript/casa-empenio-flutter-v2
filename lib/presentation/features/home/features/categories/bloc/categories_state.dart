part of 'categories_bloc.dart';

enum CategoriesStatus { initial, loading, error, loaded }

class CategoriesState extends Equatable {
  const CategoriesState({
    this.categoriesStatus = CategoriesStatus.initial,
    this.listCategories,
    this.error,
  });

  final CategoriesStatus categoriesStatus;
  final List<CategoriesEntity>? listCategories;
  final String? error;

  bool get isCategoriesLoading => categoriesStatus == CategoriesStatus.loading;
  bool get isCategoriesError => categoriesStatus == CategoriesStatus.error;

  CategoriesState copyWith({
    CategoriesStatus? categoriesStatus,
    List<CategoriesEntity>? listCategories,
    String? error,
  }) =>
      CategoriesState(
        categoriesStatus: categoriesStatus ?? this.categoriesStatus,
        listCategories: listCategories ?? this.listCategories,
        error: error,
      );

  @override
  List<Object?> get props => [
        listCategories,
        categoriesStatus,
        error,
      ];
}
