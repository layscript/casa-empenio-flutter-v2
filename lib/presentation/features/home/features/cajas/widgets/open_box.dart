import 'package:casa_empenio_pe_dev/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe_dev/presentation/features/features.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OpenBoxView extends StatefulWidget {
  const OpenBoxView({super.key});

  @override
  State<OpenBoxView> createState() => _OpenBoxViewState();
}

class _OpenBoxViewState extends State<OpenBoxView> {
  final montoCtrl = TextEditingController();
  final obsCtrl = TextEditingController();

  bool isValidMonto = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state as Authenticated;

    return BlocListener<CajasBloc, CajasState>(
      listener: (context, state) {
        if (state.isCajasFailure) {
          Navigator.pop(context);
          ErrorSnackbar.show(
            context,
            state.error ?? 'Ocurrió un error al actualizar',
          );
        }

        if (state.isCajasSuccess) {
          Navigator.pop(context, true);
          SuccessSnackbar.show(
            context,
            'Caja Actualizada Correctamente',
          );
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            const Text('Abrir Caja'),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextFormField(
              controller: montoCtrl,
              labelText: 'Monto',
              keyboardType: TextInputType.number,
              isValid: (value) {
                setState(() {
                  isValidMonto = value;
                });
              },
            ),
            const SizedBox(height: 20),
            AppTextFormField(
              controller: obsCtrl,
              labelText: 'Observaciones',
            ),
            const SizedBox(height: 20),
            SecondaryButton(
              onPressed: isValidMonto
                  ? () {
                      context.read<CajasBloc>().add(
                            OpenBox(
                              id: auth.user.id,
                              monto: montoCtrl.text,
                              obs: obsCtrl.text,
                            ),
                          );
                    }
                  : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
