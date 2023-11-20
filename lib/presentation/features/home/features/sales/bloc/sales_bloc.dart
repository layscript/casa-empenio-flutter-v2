import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'sales_event.dart';
part 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  SalesBloc() : super(SalesInitial()) {
    on<SalesEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
