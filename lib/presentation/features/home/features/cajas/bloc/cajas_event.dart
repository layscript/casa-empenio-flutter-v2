part of 'cajas_bloc.dart';

sealed class CajasEvent extends Equatable {
  const CajasEvent();

  @override
  List<Object> get props => [];
}

class GetAllCajas extends CajasEvent {}

class GetCajasOfTheDay extends CajasEvent {}

class CloseBox extends CajasEvent {
  const CloseBox({
    required this.id,
    required this.monto,
    required this.obs,
  });

  final int id;
  final String monto;
  final String obs;
}

class OpenBox extends CajasEvent {
  const OpenBox({
    required this.id,
    required this.monto,
    required this.obs,
  });

  final int id;
  final String monto;
  final String obs;
}

class IncreaseBox extends CajasEvent {
  const IncreaseBox({
    required this.id,
    required this.monto,
    required this.obs,
  });

  final int id;
  final String monto;
  final String obs;
}
