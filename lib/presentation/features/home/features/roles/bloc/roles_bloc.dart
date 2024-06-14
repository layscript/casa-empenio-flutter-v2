import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'roles_event.dart';
part 'roles_state.dart';

class RolesBloc extends Bloc<RolesEvent, RolesState> {
  RolesBloc({
    required RolRepository rolRepository,
    required ModulosRepository modulosRepository,
  })  : _rolRepository = rolRepository,
        _modulosRepository = modulosRepository,
        super(const RolesState()) {
    on<GetRoles>(_onGetRoles);
    on<SaveRol>(_onSaveRol);
    on<UpdateRol>(_onUpdateRol);
    on<SearchRolesByName>(_onSearchRolesByName);
  }

  final RolRepository _rolRepository;
  final ModulosRepository _modulosRepository;

  Future<void> _onGetRoles(
    GetRoles event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(status: RolesStatus.loading));
    final results = await Future.wait([
      _rolRepository.getRoles(),
      _modulosRepository.getAllModulos(limit: 1000),
    ]);

    final getRolesResult = results[0] as Either<String, List<RoleEntity>>;
    final getModulesResult = results[1] as Either<String, List<ModulosEntity>>;

    getRolesResult.fold(
      (error) => emit(
        state.copyWith(
          status: RolesStatus.error,
          error: error,
        ),
      ),
      (roles) {
        getModulesResult.fold(
          (error) => emit(
            state.copyWith(
              status: RolesStatus.error,
              error: error,
            ),
          ),
          (modules) => emit(
            state.copyWith(
              status: RolesStatus.loaded,
              listRoles: roles,
              listModules: modules,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSearchRolesByName(
    SearchRolesByName event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(status: RolesStatus.loading));
    final result = await _rolRepository.getRoles(
      busqueda: event.value,
      offset: 0,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          status: RolesStatus.error,
          error: error,
        ),
      ),
      (roles) => emit(
        state.copyWith(
          status: RolesStatus.loaded,
          listRoles: roles,
        ),
      ),
    );
  }

  Future<void> _onSaveRol(
    SaveRol event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(status: RolesStatus.loading));
    final result = await _rolRepository.createRol(
      nombre: event.nombre,
      modulosId: event.modulos.map((e) {
        return e.id;
      }).toList(),
    );

    result.fold(
      (error) => emit(state.copyWith(status: RolesStatus.error)),
      (success) => add(const GetRoles()),
    );
  }

  Future<void> _onUpdateRol(
    UpdateRol event,
    Emitter<RolesState> emit,
  ) async {
    emit(state.copyWith(status: RolesStatus.loading));
    final result = await _rolRepository.updateRol(
      id: event.id.toString(),
      nombre: event.nombre,
      modulosId: event.modulos.map((e) {
        return e.id;
      }).toList(),
    );

    result.fold(
      (error) => emit(state.copyWith(status: RolesStatus.error)),
      (success) => add(const GetRoles()),
    );
  }
}
