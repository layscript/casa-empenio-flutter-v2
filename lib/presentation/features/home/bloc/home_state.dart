part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    this.modulos,
    this.selected,
  });
  final List<ModulosEntity>? modulos;
  final ModulosEntity? selected;

  HomeState copyWith({
    ModulosEntity? selected,
    List<ModulosEntity>? modulos,
  }) =>
      HomeState(
        selected: selected ?? this.selected,
        modulos: modulos ?? this.modulos,
      );

  @override
  List<Object?> get props => [
        selected,
        modulos,
      ];
}
