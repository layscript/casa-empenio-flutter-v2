import 'package:casa_empenio_pe/domain/solicitud/solicitud_entity.dart';
import 'package:dartz/dartz.dart';

abstract class SolicitudRepository {
  Future<Either<String, List<SolicitudEntity>>> getSolicitudes();
  Future<Either<String, bool>> createSolicitud({
    required String prestamoId,
    required String estado,
    required int usuarioId,
  });
  Future<Either<String, bool>> updateSolicitud({
    required int solicitudId,
    required String prestamoId,
    required String estado,
    required int usuarioId,
  });
  Future<Either<String, bool>> deleteSolicitud({
    required int solicitudId,
  });

  Future<bool> getSolicitudByIdPrestamo({
    required int idPrestamo,
  });
}
