import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class SucursalRepository {
  Future<Either<String, List<SucursalEntity>>> getSucursales();
  Future<Either<String, SucursalEntity>> createSucursal({
    required String nombre,
    required String direccion,
  });
}
