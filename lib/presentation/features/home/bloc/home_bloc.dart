import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState(index: 0)) {
    on<GoToHome>(_onGoToHome);
    on<GoToLoans>(_onGoToLoans);
  }

  void _onGoToHome(GoToHome event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 0));
  }

  void _onGoToLoans(GoToLoans event, Emitter<HomeState> emit) {
    emit(state.copyWith(index: 1));
  }
}
