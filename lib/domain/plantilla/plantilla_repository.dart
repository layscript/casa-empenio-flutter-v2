import 'package:casa_empenio_pe/domain/plantilla/plantilla_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PlantillaRepository {
  Future<Either<String, List<PlantillaEntity>>> getPlantillas();
  Future<Either<String, String>> getPlantilla();
  Future<Either<String, String>> setPlantilla(String url);
}
