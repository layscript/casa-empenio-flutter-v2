import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/error_snackbar.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/overlay_loader.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/success_snackbar.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteLoanDialog extends StatelessWidget {
  const DeleteLoanDialog({
    super.key,
    required this.idLoan,
    required this.idCaja,
    this.isPayment = false,
  });
  final int idLoan;
  final bool isPayment;
  final int idCaja;

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
            ErrorSnackbar.show(
              context,
              state.error ?? 'Ocurrió un problema',
            );
            Navigator.pop(context, false);
          }

          if (state.isLoansDeleteSuccess) {
            SuccessSnackbar.show(
              context,
              'Eliminado Correctamente',
            );
            Navigator.pop(context, true);
          }
        }
      },
      child: AlertDialog(
        title: Text(
          isPayment ? 'Eliminar Pago' : 'Eliminar Préstamo',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isPayment
              ? '¿Esta seguro que desea eliminar el pago?'
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
          if (!isPayment)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              onPressed: () {
                context.read<LoansBloc>().add(
                      DeleteLoanById(
                        idLoan: idLoan,
                        userId: preferences.token?.id.toString() ?? '0',
                        idCaja: idCaja,
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
          if (isPayment)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              onPressed: () {
                context.read<LoansBloc>().add(
                      DeletePaymentLoanId(
                        paymentId: idLoan,
                        userId: preferences.token?.id.toString() ?? '0',
                        idCaja: idCaja,
                      ),
                    );
              },
              child: const Text(
                'Si, Eliminar Pago',
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
