import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CancelDialogReportLoan extends StatelessWidget {
  const CancelDialogReportLoan({super.key, required this.codigo});
  final int codigo;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state.isReportsCanceledLoading) {
          OverlayLoader.show(context);
        } else {
          OverlayLoader.hide();
          if (state.isReportsCanceledError) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: const Text(
                    'Ocurrió un error al cancelar el prestamo',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.normal),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => {
                        Navigator.pop(context),
                      },
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          } else if (state.isReportsCanceledSuccess) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Mensaje'),
                  content: const Text(
                    'Prestamo cancelado correctamente',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.normal),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => {
                        Navigator.pop(context),
                        Navigator.pop(context, true),
                      },
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          }
        }
      },
      child: AlertDialog(
        title: const Text('Cancelar Prestamo'),
        content: const Text(
          '¿Está seguro que desea cancelar el prestamo?',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Regresar',
              style: TextStyle(
                color: AppColors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ReportsBloc>().add(
                    CancelReportLoan(
                      codigo,
                    ),
                  );
            },
            child: const Text(
              'Guardar',
            ),
          ),
        ],
      ),
    );
  }
}
