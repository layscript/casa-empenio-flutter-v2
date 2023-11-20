import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState(index: 0)) {
    on<GoToHome>(_onGoToHome);
    on<GoToLoans>(_onGoToLoans);
    on<GoToReports>(_onGoToReports);
    on<GoToSales>(_onGoToSales);
    on<GoToProducts>(_onGoToProducts);
    on<GoToUsers>(_onGoToUsers);
    on<GoToInterests>(_onGoToInterests);
  }

  void _onGoToHome(GoToHome event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 0));
  }

  void _onGoToLoans(GoToLoans event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 1));
  }

  void _onGoToReports(GoToReports event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 2));
  }

  void _onGoToSales(GoToSales event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 3));
  }

  void _onGoToProducts(GoToProducts event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 4));
  }

  void _onGoToUsers(GoToUsers event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 5));
  }

  void _onGoToInterests(GoToInterests event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 6));
  }
}
