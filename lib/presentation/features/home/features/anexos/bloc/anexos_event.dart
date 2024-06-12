part of 'anexos_bloc.dart';

sealed class AnexosEvent extends Equatable {
  const AnexosEvent();

  @override
  List<Object> get props => [];
}

class GetAnexos extends AnexosEvent {
  final DateTime? inicio;
  final DateTime? fin;

  const GetAnexos({
    this.inicio,
    this.fin,
  });
}

class SaveAnexo extends AnexosEvent {
  const SaveAnexo({
    required this.description,
    required this.imagenes,
    required this.prestamoId,
  });
  final String prestamoId;
  final String description;
  final List<XFile>? imagenes;
}

class DeleteAnexo extends AnexosEvent {
  const DeleteAnexo({required this.id});
  final int id;
}
