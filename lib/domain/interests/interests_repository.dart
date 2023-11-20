import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:dartz/dartz.dart';

abstract class InterestsRepository {
  Future<Either<String, bool>> createInterests({required String interest});
  Future<Either<String, bool>> updateInterests({required Interests interests});
  Future<Either<String, bool>> deleteInterests({required int idInterest});
  Future<Either<String, List<Interests>>> getInterest();
}
