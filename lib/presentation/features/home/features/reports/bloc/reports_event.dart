part of 'reports_bloc.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class GetCategoriesEvent extends ReportsEvent {
  const GetCategoriesEvent();
}

class DeleteIncreaseEvent extends ReportsEvent {
  const DeleteIncreaseEvent(
    this.id,
    this.userId,
  );
  final int? id;
  final int? userId;
}

class ChangeCategoryEvent extends ReportsEvent {
  const ChangeCategoryEvent(this.category);
  final CategoriesEntity? category;
}

class AnularPrestamoLiquidado extends ReportsEvent {
  const AnularPrestamoLiquidado(this.codigo);
  final int? codigo;
}

class GetLoadInitialDataContracts extends ReportsEvent {
  const GetLoadInitialDataContracts({
    required this.start,
    required this.end,
  });

  final DateTime? start;
  final DateTime? end;
}

class GetLoadInitialDataPayments extends ReportsEvent {
  const GetLoadInitialDataPayments({
    required this.start,
    required this.end,
  });

  final DateTime? start;
  final DateTime? end;
}

class GetDetailsReportLoan extends ReportsEvent {
  const GetDetailsReportLoan(this.value);
  final int value;
}

class GetDetailsReportPay extends ReportsEvent {
  const GetDetailsReportPay(this.value);
  final int value;
}

class CancelReportLoan extends ReportsEvent {
  const CancelReportLoan({
    required this.loanId,
    required this.userId,
  });
  final int loanId;
  final String userId;
}

// TAGS
class ChangeVigentContracts extends ReportsEvent {
  const ChangeVigentContracts(this.value);
  final bool value;
}

class ChangeVencidoContracts extends ReportsEvent {
  const ChangeVencidoContracts(this.value);
  final bool value;
}

class ChangePagadoContracts extends ReportsEvent {
  const ChangePagadoContracts(this.value);
  final bool value;
}

class ChangeVentaContracts extends ReportsEvent {
  const ChangeVentaContracts(this.value);
  final bool value;
}

class ChangeLiquidadoContracts extends ReportsEvent {
  const ChangeLiquidadoContracts(this.value);
  final bool value;
}

class ChangeCanceladoContracts extends ReportsEvent {
  const ChangeCanceladoContracts(this.value);
  final bool value;
}
