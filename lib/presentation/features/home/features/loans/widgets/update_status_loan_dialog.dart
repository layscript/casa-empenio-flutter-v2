import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/error_snackbar.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/overlay_loader.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/success_snackbar.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateStatusLoanDialog extends StatefulWidget {
  const UpdateStatusLoanDialog({
    super.key,
    required this.idLoan,
  });
  final int idLoan;

  @override
  State<UpdateStatusLoanDialog> createState() => _UpdateStatusLoanDialogState();
}

class _UpdateStatusLoanDialogState extends State<UpdateStatusLoanDialog> {
  String? status;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoansBloc, LoansState>(
      listener: (context, state) {
        if (state.isLoansUpdateStatusLoading) {
          OverlayLoader.show(context);
        } else {
          OverlayLoader.hide();
          if (state.isLoansUpdateStatusError) {
            ErrorSnackbar.show(context, 'Ocurrió un problema');
          }

          if (state.isLoansUpdateStatusSuccess) {
            SuccessSnackbar.show(
              context,
              'Estado del Préstamo Actualizado',
            );
            Navigator.pop(context, true);
          }
        }
      },
      child: AlertDialog(
        title: const Text('Actualizar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDropdownButtonFormField<String?>(
              value: status,
              labelText: 'Estado',
              onChanged: (e) {
                setState(() {
                  status = e;
                });
              },
              items: ['VENTA']
                  .map(
                    (e) => DropdownMenuItem<String?>(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
            ),
          ],
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
            onPressed: status != null
                ? () {
                    context.read<LoansBloc>().add(
                          UpdateStatusLoanById(
                            idLoan: widget.idLoan,
                            value: status ?? '',
                          ),
                        );
                  }
                : null,
            child: const Text(
              'Aceptar',
            ),
          ),
        ],
      ),
    );
  }
}
