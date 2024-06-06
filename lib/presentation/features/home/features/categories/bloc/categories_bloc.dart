import 'dart:async';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc({required CategoriesRepository categoriesRepository})
      : _categoriesRepository = categoriesRepository,
        super(const CategoriesState()) {
    on<GetCategories>(_onGetCategories);
    on<SaveCategories>(_onSaveCategories);
    on<UpdateCategories>(_onUpdateCategories);
    on<DeleteCategories>(_onDeleteCategories);
  }

  final CategoriesRepository _categoriesRepository;

  Future<void> _onGetCategories(
    GetCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: CategoriesStatus.loading));
    final result = await _categoriesRepository.getCategories();

    result.fold(
      (error) => emit(
        state.copyWith(
            categoriesStatus: CategoriesStatus.error,
            error: 'Ocurrió un problema'),
      ),
      (listCategories) => emit(
        state.copyWith(
          categoriesStatus: CategoriesStatus.loaded,
          listCategories: listCategories,
        ),
      ),
    );
  }

  Future<void> _onSaveCategories(
    SaveCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: CategoriesStatus.loading));
    final result =
        await _categoriesRepository.createCategory(value: event.data);
    if (result) {
      add(GetCategories());
    } else {
      emit(
        state.copyWith(
          error: 'Ocurrió un error',
          categoriesStatus: CategoriesStatus.error,
        ),
      );
    }
  }

  Future<void> _onUpdateCategories(
    UpdateCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: CategoriesStatus.loading));
    final result = await _categoriesRepository.updateCategory(
      value: event.data,
      idCategory: event.id.toString(),
    );
    if (result) {
      add(GetCategories());
    } else {
      emit(
        state.copyWith(
          error: 'Ocurrió un error',
          categoriesStatus: CategoriesStatus.error,
        ),
      );
    }
  }

  Future<void> _onDeleteCategories(
    DeleteCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: CategoriesStatus.loading));
    final result = await _categoriesRepository.deleteCategory(
      idCategory: event.id,
    );
    if (result) {
      add(GetCategories());
    } else {
      emit(
        state.copyWith(
          error: 'Ocurrió un error',
          categoriesStatus: CategoriesStatus.error,
        ),
      );
    }
  }
}
