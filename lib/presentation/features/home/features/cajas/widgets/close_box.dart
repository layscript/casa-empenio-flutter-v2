import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/desglose_medios.dart';
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
  void initState() {
    super.initState();
    montoCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

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
                  '1) Cuenta el dinero que hay físicamente en caja. 2) Escribe ese monto. 3) Mira la diferencia: si es 0 la caja cuadra; si no, explica el motivo en observaciones.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 14),
              AppTextFormField(
                controller: montoCtrl,
                labelText: 'Dinero contado en caja (S/.)',
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
                    child: Column(
                      children: [
                        Text(
                          'Saldo Teórico (lo que debe haber): s/.${movimientoDiferencia.toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Efectivo que debe haber en mano: s/.${efectivoEnMano(movimientos).toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                        if (double.tryParse(montoCtrl.text) != null) ...[
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final dif = double.parse(montoCtrl.text) -
                                movimientoDiferencia;
                            return Text(
                              dif.abs() < 0.005
                                  ? '✔ La caja cuadra'
                                  : (dif < 0
                                      ? '⚠ Faltan s/.${dif.abs().toStringAsFixed(2)}'
                                      : '⚠ Sobran s/.${dif.toStringAsFixed(2)}'),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }),
                        ],
                      ],
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
