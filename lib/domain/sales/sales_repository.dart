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
}
