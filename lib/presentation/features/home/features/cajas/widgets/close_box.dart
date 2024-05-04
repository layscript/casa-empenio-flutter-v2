import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CloseBoxView extends StatefulWidget {
  const CloseBoxView({super.key});

  @override
  State<CloseBoxView> createState() => _CloseBoxViewState();
}

class _CloseBoxViewState extends State<CloseBoxView> {
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
              const Text('Cerrar Caja'),
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
              /*  Text(
                '${state.movements?.movimientos?.length}',
              ), */
              Builder(
                builder: (context) {
                  final movimientos = state.movements?.movimientos ?? [];
                  var movimientoDiferencia = 0.0;
                  if (movimientos.isNotEmpty) {
                    for (var movimiento in movimientos) {
                      if (movimiento.suma == true) {
                        movimientoDiferencia +=
                            double.parse(movimiento.monto.toString());
                      } else {
                        movimientoDiferencia -=
                            double.parse(movimiento.monto.toString());
                      }
                    }
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Saldo Teórico: s/.$movimientoDiferencia',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              SecondaryButton(
                onPressed: isValidMonto
                    ? () {
                        context.read<CajasBloc>().add(
                              CloseBox(
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
        );
      },
    );
  }
}
