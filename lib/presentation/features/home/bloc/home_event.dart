part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class GoToHome extends HomeEvent {}

class GoToOpenCaja extends HomeEvent {}

/* class GoToLoans extends HomeEvent {}

class GoToReports extends HomeEvent {}

class GoToSales extends HomeEvent {}

class GoToProducts extends HomeEvent {}

class GoToUsers extends HomeEvent {}

class GoToInterests extends HomeEvent {}

class GoToCategories extends HomeEvent {}

class GoToCajas extends HomeEvent {}


class GoToExpenses extends HomeEvent {}

class GoToHistorial extends HomeEvent {}

class GoToPayUsers extends HomeEvent {}

class GoToPerdonados extends HomeEvent {}

class GoToPlantillas extends HomeEvent {}

class GoToProformas extends HomeEvent {}

class GoToAnexos extends HomeEvent {}

class GoToModulos extends HomeEvent {}

class GoToRoles extends HomeEvent {} */

class GoToPage extends HomeEvent {
  const GoToPage(this.e);
  final ModulosEntity e;

  @override
  List<Object> get props => [e];
}

class GetAllModulos extends HomeEvent {
  const GetAllModulos();
}
