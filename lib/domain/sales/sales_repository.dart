import 'package:casa_empenio_pe/domain/sales/sales_entity.dart';
import 'package:dartz/dartz.dart';

abstract class SalesRepository {
  Future<Either<String, List<SalesEntity>>> getSalesByRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int sucursalId,
    required int userId,
  });

  Future<Either<String, List<SalesEntity>>> getSalesByUserIdRangeDate({
    required DateTime inicio,
    required DateTime fin,
    required int userId,
    required int sucursalId,
  });

  Future<bool> createSalesProduct(Map<String, dynamic> data);

  /// Registra la venta SIN emitir boleta. Devuelve el id de la venta (o null si falló).
  Future<int?> registrarVenta(Map<String, dynamic> data);

  /// Emite la boleta electrónica de una venta ya registrada.
  Future<bool> emitirBoleta(int ventaId);

  /// A quién se vendió el bien de un préstamo.
  Future<List<Map<String, dynamic>>> ventasDePrestamo(int codigoPrestamo);

  /// Guarda el contrato firmado. Devuelve null si salió bien, o el mensaje de error.
  Future<String?> guardarContratoVenta(Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>> contratosDePrestamo(int codigoPrestamo);

  /// El cliente cancela el saldo de una venta con adelanto. Null = bien; si no, el error.
  Future<String?> cancelarSaldoVenta({
    required int ventaId,
    required int usuarioId,
    required int sucursalId,
    double recargo = 0,
  });

  /// El cliente desiste y se le devuelve el adelanto. Null = bien; si no, el error.
  Future<String?> desistirVenta({
    required int ventaId,
    required int usuarioId,
    required int sucursalId,
    double retener = 0,
    String motivo = '',
  });

  /// Tareas de cobranza / adjudicación pendientes de la sucursal.
  Future<List<Map<String, dynamic>>> tareasCobranza(int sucursalId);

  /// Avisos registrados y procesos de un préstamo.
  Future<Map<String, dynamic>> detalleCobranza(int codigoPrestamo);

  /// POST a /adjudicacion/prestamo/{codigo}/{accion}. Null = bien; si no, el error.
  Future<String?> accionCobranza(
    int codigoPrestamo,
    String accion,
    Map<String, dynamic> body,
  );
}
