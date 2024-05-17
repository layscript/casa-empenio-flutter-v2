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
        print('_staeeeeee: ${state.statusCanceledContracts}');
        if (state.isReportsContractCanceledError) {
          ErrorSnackbar.show(
            context,
            state.message ?? 'Ocurrió un error al eliminar el préstamo',
          );
          Navigator.pop(context);
        }
        if (state.isReportsContractCanceledSuccess) {
          SuccessSnackbar.show(
            context,
            'Eliminado correctamente',
          );
          Navigator.pop(context);
        }
      },
      child: AlertDialog(
        title: const Text('Eliminar Prestamo'),
        content: BlocBuilder<ReportsBloc, ReportsState>(
          builder: (context, state) {
            if (state.isReportsContractCanceledLoading) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿Está seguro que desea eliminar el prestamo?',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Regresar',
                      ),
                    ),
                    const SizedBox(width: 15),
                    TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.blue),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      onPressed: state.isReportsContractCanceledLoading
                          ? null
                          : () {
                              //Navigator.pop(context);

                              context.read<ReportsBloc>().add(
                                    CancelReportLoan(
                                      loanId: codigo,
                                      userId: preferences?.id.toString() ?? '1',
                                      idCaja: idCaja,
                                    ),
                                  );
                            },
                      child: const Text('Si, Eliminar'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
