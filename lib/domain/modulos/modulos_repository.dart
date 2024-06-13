import 'package:casa_empenio_pe/domain/modulos/modulos_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ModulosRepository {
  Future<Either<String, List<ModulosEntity>>> getAllModulos({
    String? busqueda,
    int? offset,
  });
}
