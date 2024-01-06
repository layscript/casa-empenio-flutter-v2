import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/error_snackbar.dart';
import 'package:casa_empenio_pe/presentation/app/utils/overlay_loader.dart';
import 'package:casa_empenio_pe/presentation/app/utils/success_snackbar.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteLoanDialog extends StatelessWidget {
  const DeleteLoanDialog({
    super.key,
    required this.idLoan,
  });
  final int idLoan;

  @override
  Widget build(BuildContext context) {
    final preferences = context.read<Preferences>();

    return BlocListener<LoansBloc, LoansState>(
      listener: (context, state) {
        if (state.isLoansDeleteLoading) {
          OverlayLoader.show(context);
        } else {
          OverlayLoader.hide();
          if (state.isLoansDeleteError) {
            ErrorSnackbar.show(context, 'Ocurrió un problema');
          }

          if (state.isLoansDeleteSuccess) {
            SuccessSnackbar.show(
              context,
              'Préstamo Eliminado',
            );
            Navigator.pop(context, true);
          }
        }
      },
      child: AlertDialog(
        title: const Text('Eliminar '),
        content: const Text(
          '¿Esta seguro que desea eliminar el prestamo?',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<LoansBloc>().add(
                    DeleteLoanById(
                      idLoan: idLoan,
                      userId: preferences.token?.id.toString() ?? '0',
                    ),
                  );
            },
            child: const Text(
              'Aceptar',
            ),
          ),
        ],
      ),
    );
  }
}
