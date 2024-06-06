import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnularDialogReport extends StatelessWidget {
  const AnularDialogReport({
    super.key,
    required this.codigo,
  });
  final int? codigo;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) async {
        if (state.isReportsCanceledLoading) {
          OverlayLoader.show(context);
        } else {
          OverlayLoader.hide();
          if (state.isReportsCanceledError) {
            ErrorSnackbar.show(context, 'Ocurrió un error, intente de nuevo');
          }
          if (state.isReportsCanceledSuccess) {
            SuccessSnackbar.show(context, 'Actualizado correctamente');
            //Navigator.pop(context, true);
          }
        }
      },
      child: AlertDialog(
        title: const Text('Anular/Cancelar'),
        content: const Text(
          '¿Estás seguro que deseas cancelar/anular el prestamo?',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: AppColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<ReportsBloc>().add(
                  AnularPrestamoLiquidado(codigo),
                ),
            child: const Text(
              'Si, cancelar',
            ),
          ),
        ],
      ),
    );
  }
}
