import 'package:casa_empenio_pe/domain/anexo/anexo_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AnexoRepository {
  Future<Either<String, bool>> createAnexo({
    required String description,
    required List<Map<dynamic, dynamic>> url,
    required String prestamoId,
  });

  Future<Either<String, List<AnexoEntity>>> getAnexos({
    required DateTime inicio,
    required DateTime fin,
    required int sucursalId,
  });

  Future<Either<String, List<AnexoEntity>>> getAnexoByPrestamo({
    required String prestamoId,
  });

  Future<Either<String, String>> createImage({
    required String path,
  });

  Future<Either<String, bool>> deleteAnexo({
    required String id,
  });
}
