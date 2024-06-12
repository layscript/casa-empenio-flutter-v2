part of 'anexos_bloc.dart';

enum AnexosStatus { initial, loading, error, loaded, success }

class AnexosState extends Equatable {
  const AnexosState({
    required this.startAnexo,
    required this.endAnexo,
    this.anexosStatus = AnexosStatus.initial,
    required this.listAnexos,
    this.error,
  });

  final AnexosStatus anexosStatus;
  final List<AnexoEntity> listAnexos;
  final String? error;

  final DateTime startAnexo;
  final DateTime endAnexo;

  bool get isAnexosLoading => anexosStatus == AnexosStatus.loading;
  bool get isAnexosError => anexosStatus == AnexosStatus.error;

  AnexosState copyWith({
    AnexosStatus? anexosStatus,
    List<AnexoEntity>? listAnexos,
    String? error,
    DateTime? startAnexo,
    DateTime? endAnexo,
  }) =>
      AnexosState(
        error: error ?? this.error,
        listAnexos: listAnexos ?? this.listAnexos,
        anexosStatus: anexosStatus ?? this.anexosStatus,
        startAnexo: startAnexo ?? this.startAnexo,
        endAnexo: endAnexo ?? this.endAnexo,
      );

  @override
  List<Object?> get props => [
        anexosStatus,
        listAnexos,
        error,
        startAnexo,
        endAnexo,
      ];
}
