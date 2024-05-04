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
    this.isAnular = false,
  });
  final int idLoan;
  final bool isAnular;

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
              state.error ?? 'Préstamo Eliminado',
            );
            Navigator.pop(context, true);
          }
        }
      },
      child: AlertDialog(
        title: Text(
          isAnular ? 'Anular Préstamo' : 'Eliminar Préstamo',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isAnular
              ? '¿Esta seguro que desea anular el prestamo?'
              : '¿Esta seguro que desea eliminar el prestamo?',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.white,
              ),
            ),
          ),
          if (!isAnular)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              onPressed: () {
                context.read<LoansBloc>().add(
                      DeleteLoanById(
                        idLoan: idLoan,
                        userId: preferences.token?.id.toString() ?? '0',
                      ),
                    );
              },
              child: const Text(
                'Si, Eliminar',
                style: TextStyle(
                  color: AppColors.white,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              onPressed: () {
                context.read<LoansBloc>().add(
                      AnularLoanId(
                        idLoan: idLoan,
                        userId: preferences.token?.id.toString() ?? '0',
                      ),
                    );
              },
              child: const Text(
                'Si, Anular',
                style: TextStyle(
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
