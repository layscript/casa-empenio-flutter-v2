import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/error_snackbar.dart';
import 'package:casa_empenio_pe/presentation/app/utils/overlay_loader.dart';
import 'package:casa_empenio_pe/presentation/app/utils/success_snackbar.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteLoanDialog extends StatefulWidget {
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
  State<DeleteLoanDialog> createState() => _DeleteLoanDialogState();
}

class _DeleteLoanDialogState extends State<DeleteLoanDialog> {
  final TextEditingController _motivoCtrl = TextEditingController();
  String? _errorMotivo;

  int get idLoan => widget.idLoan;
  bool get isPayment => widget.isPayment;
  int get idCaja => widget.idCaja;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

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
              isPayment ? 'Pago anulado y registrado' : 'Eliminado Correctamente',
            );
            Navigator.pop(context, true);
          }
        }
      },
      child: AlertDialog(
        title: Text(
          isPayment ? 'Anular pago' : 'Eliminar Préstamo',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: isPayment
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'El pago NO se borra: queda anulado y registrado '
                      '(quién, cuándo y por qué) en caja, movimientos y '
                      'auditoría. El préstamo vuelve a mostrar ese monto como '
                      'pendiente.',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _motivoCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Motivo (obligatorio)',
                        hintText: 'Ej. Me equivoqué de monto',
                        errorText: _errorMotivo,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              )
            : const Text(
                '¿Esta seguro que desea eliminar el prestamo?',
                style: TextStyle(
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
                final motivo = _motivoCtrl.text.trim();
                if (motivo.length < 3) {
                  setState(() => _errorMotivo = 'Escriba por qué se anula');
                  return;
                }
                context.read<LoansBloc>().add(
                      DeletePaymentLoanId(
                        paymentId: idLoan,
                        userId: preferences.token?.id.toString() ?? '0',
                        idCaja: idCaja,
                        motivo: motivo,
                      ),
                    );
              },
              child: const Text(
                'Sí, anular pago',
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
