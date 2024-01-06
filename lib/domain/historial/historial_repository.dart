import 'package:casa_empenio_pe/domain/historial/historial_entity.dart';
import 'package:dartz/dartz.dart';

abstract class HistorialRepository {
  Future<Either<String, List<HistorialEntity>?>> getHistorialByUser({
    required int userId,
  });
}
