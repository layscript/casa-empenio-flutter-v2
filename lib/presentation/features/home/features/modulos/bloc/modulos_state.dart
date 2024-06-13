part of 'modulos_bloc.dart';

enum ModulosStatus { initial, loading, error, loaded }

class ModulosState extends Equatable {
  const ModulosState({
    this.status = ModulosStatus.initial,
    this.listModulos = const <ModulosEntity>[],
    this.error,
  });

  final ModulosStatus status;
  final List<ModulosEntity> listModulos;
  final String? error;

  ModulosState copyWith({
    ModulosStatus? status,
    List<ModulosEntity>? listModulos,
    String? error,
  }) =>
      ModulosState(
        status: status ?? this.status,
        listModulos: listModulos ?? this.listModulos,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [
        status,
        error,
        listModulos,
      ];
}
