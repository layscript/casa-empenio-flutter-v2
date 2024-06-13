part of 'modulos_bloc.dart';

sealed class ModulosEvent extends Equatable {
  const ModulosEvent();

  @override
  List<Object> get props => [];
}

final class GetModulos extends ModulosEvent {
  const GetModulos();
}

final class SearchModuloByName extends ModulosEvent {
  final String value;
  const SearchModuloByName({required this.value});
}
