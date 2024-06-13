import 'package:casa_empenio_pe/presentation/app/utils/button_state_error.dart';
import 'package:casa_empenio_pe/presentation/app/utils/button_state_loading.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/modulos/bloc/modulos_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/modulos/views/modulos_view_loaded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModulosView extends StatelessWidget {
  const ModulosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => ModulosBloc(
        modulosRepository: context.read(),
      )..add(const GetModulos()),
      child: Builder(
        builder: (context) {
          return BlocBuilder<ModulosBloc, ModulosState>(
            builder: (context, state) {
              switch (state.status) {
                case ModulosStatus.initial || ModulosStatus.loading:
                  return const ButtonStateLoading();

                case ModulosStatus.error:
                  return ButtonStateError(
                    onPressed: () {
                      context.read<ModulosBloc>().add(const GetModulos());
                    },
                  );

                case ModulosStatus.loaded:
                  return Center(
                    child: ModulosViewLoaded(state: state)
                  );
              }
            },
          );
        },
      ),
    );
  }
}
