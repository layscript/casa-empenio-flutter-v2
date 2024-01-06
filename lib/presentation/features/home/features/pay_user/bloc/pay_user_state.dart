part of 'pay_user_bloc.dart';

enum PayUserStatus {
  initial,
  loading,
  error,
  loaded,
  success,
  failure,
}

class PayUserState extends Equatable {
  const PayUserState({
    this.openBox = false,
    this.payUserStatus = PayUserStatus.initial,
    this.listPayments,
    this.error,
  });

  final bool openBox;
  final PayUserStatus payUserStatus;
  final List<MotionEntity>? listPayments;
  final String? error;

  PayUserState copyWith({
    bool? openBox,
    PayUserStatus? payUserStatus,
    List<MotionEntity>? listPayments,
    String? error,
  }) =>
      PayUserState(
        openBox: openBox ?? this.openBox,
        payUserStatus: payUserStatus ?? this.payUserStatus,
        listPayments: listPayments ?? this.listPayments,
        error: error,
      );

  bool get isPaymentsFailure => payUserStatus == PayUserStatus.failure;
  bool get isPaymentsSuccess => payUserStatus == PayUserStatus.success;

  @override
  List<Object?> get props => [
        openBox,
        payUserStatus,
        listPayments,
        error,
      ];
}
