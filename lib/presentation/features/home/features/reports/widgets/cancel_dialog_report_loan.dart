import 'package:casa_empenio_pe/domain/preferences/preferences.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CancelDialogReportLoan extends StatelessWidget {
  const CancelDialogReportLoan({
    super.key,
    required this.codigo,
    required this.idCaja,
  });
  final int codigo;
  final int idCaja;

  @override
  Widget build(BuildContext context) {
    final preferences = context.read<Preferences>().token;

    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state.isReportsContractCanceledLoading) {
          OverlayLoader.show(context);
        } else {
          OverlayLoader.hide();
          if (state.isReportsContractCanceledError) {
            ErrorSnackbar.show(
              context,
              state.message ?? 'Ocurrió un error al eliminar el prestamo',
            );
          }
          if (state.isReportsContractCanceledSuccess) {
            SuccessSnackbar.show(context, 'Eliminado correctamente');
          }
        }
      },
      child: AlertDialog(
        title: const Text('Eliminar Prestamo'),
        content: const Text(
          '¿Está seguro que desea eliminar el prestamo?',
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
              Navigator.pop(context);
              context.read<ReportsBloc>().add(
                    CancelReportLoan(
                      loanId: codigo,
                      userId: preferences?.id.toString() ?? '1',
                      idCaja: idCaja,
                    ),
                  );
            },
            child: const Text(
              'Si, Eliminar',
            ),
          ),
        ],
      ),
    );
  }
}
