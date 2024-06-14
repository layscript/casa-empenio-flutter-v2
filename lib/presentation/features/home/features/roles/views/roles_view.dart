import 'package:casa_empenio_pe/presentation/app/utils/button_state_error.dart';
import 'package:casa_empenio_pe/presentation/app/utils/button_state_loading.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/roles/views/roles_view_loaded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolesView extends StatelessWidget {
  const RolesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => RolesBloc(
        rolRepository: context.read(),
        modulosRepository: context.read(),
      )..add(const GetRoles()),
      child: Builder(
        builder: (context) {
          return BlocBuilder<RolesBloc, RolesState>(
            builder: (context, state) {
              switch (state.status) {
                case RolesStatus.initial || RolesStatus.loading:
                  return const ButtonStateLoading();

                case RolesStatus.error:
                  return ButtonStateError(
                    onPressed: () {
                      context.read<RolesBloc>().add(const GetRoles());
                    },
                  );

                case RolesStatus.loaded:
                  return Center(child: RolesViewLoaded(state: state));
              }
            },
          );
        },
      ),
    );
  }
}
