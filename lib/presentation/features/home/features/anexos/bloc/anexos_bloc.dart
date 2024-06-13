import 'package:casa_empenio_pe/domain/anexo/anexo_repository.dart';
import 'package:casa_empenio_pe/domain/preferences/preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/domain/anexo/anexo_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

part 'anexos_event.dart';
part 'anexos_state.dart';

final _initialState = AnexosState(
  startAnexo: DateTime.now(),
  endAnexo: DateTime.now(),
  anexosStatus: AnexosStatus.initial,
  error: null,
  listAnexos: const [],
);

class AnexosBloc extends Bloc<AnexosEvent, AnexosState> {
  AnexosBloc({
    required AnexoRepository anexoRepository,
    required Preferences preferences,
  })  : _anexoRepository = anexoRepository,
        _preferences = preferences,
        super(_initialState) {
    on<GetAnexos>(_onGetAnexos);
    on<SaveAnexo>(_onSaveAnexo);
    on<DeleteAnexo>(_onDeleteAnexo);
  }

  final AnexoRepository _anexoRepository;
  final Preferences _preferences;

  Future<void> _onGetAnexos(
    GetAnexos event,
    Emitter<AnexosState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          anexosStatus: AnexosStatus.loading,
          startAnexo: event.inicio,
          endAnexo: event.fin,
        ),
      );
      final result = await _anexoRepository.getAnexos(
        inicio: event.inicio ?? state.startAnexo,
        fin: event.fin ?? state.endAnexo,
        sucursalId: _preferences.token?.sucursal?.id ?? 1,
      );
      result.fold(
        (message) {
          emit(
            state.copyWith(
              anexosStatus: AnexosStatus.error,
            ),
          );
        },
        (anexos) {
          emit(
            state.copyWith(
              anexosStatus: AnexosStatus.loaded,
              listAnexos: anexos,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
            anexosStatus: AnexosStatus.loaded,
            listAnexos: [],
            error: e.toString()),
      );
    }
  }

  Future<void> _onSaveAnexo(
    SaveAnexo event,
    Emitter<AnexosState> emit,
  ) async {
    emit(
      state.copyWith(
        anexosStatus: AnexosStatus.loading,
      ),
    );

    List<String> images = [];

    if (event.imagenes != null) {
      for (var img in event.imagenes!) {
        final url = await _anexoRepository.createImage(path: img.path);
        url.fold(
          (error) => emit(
            state.copyWith(
              anexosStatus: AnexosStatus.error,
              error: error,
            ),
          ),
          (success) => images.add(success),
        );
      }

      if (images.isNotEmpty) {
        final result = await _anexoRepository.createAnexo(
          description: event.description,
          prestamoId: event.prestamoId,
          url: images.map((e) {
            return {'url': e};
          }).toList(),
        );

        result.fold(
          (error) => emit(
            state.copyWith(
              anexosStatus: AnexosStatus.error,
              error: error,
            ),
          ),
          (success) {
            add(const GetAnexos());
          },
        );
      }
    }
  }

  Future<void> _onDeleteAnexo(
    DeleteAnexo event,
    Emitter<AnexosState> emit,
  ) async {
    emit(
      state.copyWith(
        anexosStatus: AnexosStatus.loading,
      ),
    );

    final result = await _anexoRepository.deleteAnexo(id: event.id.toString());

    result.fold(
      (error) => emit(
        state.copyWith(
          anexosStatus: AnexosStatus.error,
          error: error,
        ),
      ),
      (success) {
        add(const GetAnexos());
      },
    );
  }
}
