import 'package:dartz/dartz.dart';

abstract class PlantillaRepository {
  Future<Either<String, String>> getPlantilla();
  Future<Either<String, String>> setPlantilla(String url);
}
