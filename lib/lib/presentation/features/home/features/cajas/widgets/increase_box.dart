import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncreaseBoxView extends StatefulWidget {
  const IncreaseBoxView({super.key});

  @override
  State<IncreaseBoxView> createState() => _IncreaseBoxViewState();
}

class _IncreaseBoxViewState extends State<IncreaseBoxView> {
  final montoCtrl = TextEditingController();
  final obsCtrl = TextEditingController();

  bool isValidMonto = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state as Authenticated;

    return BlocConsumer<CajasBloc, CajasState>(
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
      builder: (context, state) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('Aumentar Monto'),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Úsalo cuando METES más dinero a la caja (ej.: aporte del dueño). Explica el motivo en observaciones.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: montoCtrl,
                labelText: 'Monto a aumentar (S/.)',
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
                              IncreaseBox(
                                id: auth.user?.id ?? 1,
                                monto: montoCtrl.text,
                                obs: obsCtrl.text,
                              ),
                            );
                      }
                    : null,
                child: const Text('Continuar'),
              ),
            ],
          )),
        );
      },
    );
  }
}
