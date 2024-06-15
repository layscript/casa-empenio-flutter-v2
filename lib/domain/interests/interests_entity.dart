import 'package:equatable/equatable.dart';

class InterestsEntity extends Equatable {
  const InterestsEntity({
    required this.id,
    required this.intereses,
  });

  final int id;
  final String intereses;

  static List<InterestsEntity> listGetInterestFromMap(
    Map<String, dynamic> map,
  ) {
    final list = map['body'] as List<dynamic>;
    return list
        .map((e) => getInterestFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static InterestsEntity getInterestFromMap(Map<String, dynamic> map) {
    return InterestsEntity(
      id: map['id'] as int,
      intereses: map['interes'] as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        intereses,
      ];
}
