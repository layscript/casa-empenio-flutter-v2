// ignore_for_file: prefer_is_empty

import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/views/loans_loaded_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansView extends StatelessWidget {
  const LoansView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();

    return BlocProvider(
      lazy: false,
      create: (context) => LoansBloc(
        customerRepository: context.read(),
        loansRepository: context.read(),
        cajaRepository: context.read(),
        preferences: context.read(),
        solicitudRepository: context.read(),
        anexoRepository: context.read(),
        categoriesRepository: context.read(),
      )..add(GetCashStatus()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<LoansBloc, LoansState>(
            listener: (context, state) {
              if (state.isSolicitudLoading || state.isAnexosLoading) {
                OverlayLoader.show(context);
              } else {
                OverlayLoader.hide();
                if (state.isSolicitudError) {
                  Navigator.pop(context);
                  ErrorSnackbar.show(context, state.error ?? '');
                }

                if (state.isSolicitudSuccess) {
                  Navigator.pop(context);
                  SuccessSnackbar.show(
                      context, 'Solicitud enviada correctamente');
                }

                if (state.isAnexosError) {
                  ErrorSnackbar.show(context, state.error ?? '');
                }

                if (state.isAnexosSuccess) {
                  SuccessSnackbar.show(
                    context,
                    'Visita agregado correctamente',
                  );
                }
              }

              if (state.openBox == true) {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return const AlertGoToCaja();
                  },
                ).then(
                  (value) {
                    homeBloc.add(GoToOpenCaja());
                  },
                );
              }
            },
            builder: (context, state) {
              final loansBloc = context.read<LoansBloc>();
              if (state.loansStatus == LoansStatus.error) {
                return ButtonStateError(
                  message: state.error,
                  onPressed: () {
                    loansBloc.add(GetCashStatus());
                  },
                );
              }

              return LoansLoadedView(
                loansBloc: loansBloc,
                state: state,
              );
            },
          );
        },
      ),
    );
  }
}
