import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PaymentLoanDialogClient extends StatefulWidget {
  const PaymentLoanDialogClient({
    super.key,
    required this.nroPrestamo,
  });
  final int? nroPrestamo;

  @override
  State<PaymentLoanDialogClient> createState() =>
      _PaymentLoanDialogClientState();
}

class _PaymentLoanDialogClientState extends State<PaymentLoanDialogClient> {
  final montoCtrl = TextEditingController();
  List<XFile>? selectedPhotosLiquidar = [];

  bool liquidar = false;
  double restante = 0;
  bool efectivo = false;

  @override
  void initState() {
    super.initState();
    if (widget.nroPrestamo != null) {
      context.read<LoansBloc>().add(GetDetailsLoan(widget.nroPrestamo!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>().state as Authenticated;

    return GestureDetector(
      onTap: () => Keyboard.unfocus(context),
      child: AlertDialog(
        insetPadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        content: BlocConsumer<LoansBloc, LoansState>(
          listener: (context, state) {
            if (state.isLoansPaymentSuccess) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Pago registrado',
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                    content:
                        const Text('El pago se ha registrado correctamente'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context, true);
                        },
                        child: const Text('Aceptar'),
                      ),
                    ],
                  );
                },
              );
            }

            if (state.isLoansSettlementSuccess) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Liquidación registrado',
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                    content: const Text(
                        'La liquidación se ha registrado correctamente'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          //Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.pop(context, true);
                        },
                        child: const Text('Aceptar'),
                      ),
                    ],
                  );
                },
              );
            }

            if (state.isLoansPaymentError) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Ocurrió un error',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    content: Text(state.error ??
                        'No se pudo registrar el pago. Verifique los datos e intente nuevamente.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Aceptar'),
                      ),
                    ],
                  );
                },
              );
            }

            if (state.isLoansSettlementError) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Ocurrió un error',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    content: Text(state.error ??
                        'No se pudo completar la liquidación. Verifique los datos e intente nuevamente.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          //Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Aceptar'),
                      ),
                    ],
                  );
                },
              );
            }
          },
          builder: (context, state) {
            if (state.loanDetails == null) {
              return const SizedBox(
                width: 320,
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              final loan = state.loanDetails;

              final montosPagos = loan?.pagos?.map((e) {
                return double.parse(e.monto ?? '0.00');
              }).toList();

              final resultMontos = montosPagos != null
                  ? montosPagos.isNotEmpty
                      ? montosPagos.reduce((value, element) => value + element)
                      : null
                  : null;

              final montoRestante = double.parse(loan?.monto ?? '0.00') +
                  double.parse(loan?.ganancia ?? '0.00') -
                  (resultMontos ?? 0.00);

              return SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            liquidar ? 'Liquidar Prestamo' : 'Registrar Pago',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: liquidar ? Colors.red : Colors.black,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                liquidar = !liquidar;
                              });
                            },
                            icon: Icon(
                              liquidar ? Icons.lock : Icons.lock_clock_sharp,
                              color: liquidar ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ItemPaymentLoan(
                        title: 'Fecha de Pago',
                        value: DateFormat('dd/MM/yyyy - kk:mm').format(
                          DateTime.now(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ItemPaymentLoan(
                        title: 'Fecha de Vencimiento',
                        value: DateFormat('dd/MM/yyyy').format(
                          loan?.fechaPago == null
                              ? DateTime.now()
                              : DateTime.parse(loan!.fechaPago!).toLocal(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (loan?.pagos == null) ...[
                        const Text(
                          'Cargando información...',
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (loan?.ganancia != null) ...[
                        ItemPaymentLoan(
                          title: 'Capital',
                          value:
                              'S/. ${oCcy.format(double.parse(loan!.monto.toString()))}',
                        ),
                        const SizedBox(height: 10),
                        ItemPaymentLoan(
                          title: 'Interés',
                          value:
                              'S/. ${oCcy.format(double.parse(loan.ganancia.toString()))}',
                        ),
                        const SizedBox(height: 10),
                        ItemPaymentLoan(
                          title: 'Deuda Total',
                          value:
                              'S/. ${oCcy.format(double.parse(loan!.ganancia.toString()) + double.parse(loan.monto!))}',
                        ),
                        const SizedBox(height: 10),
                        ItemPaymentLoan(
                          title: 'Deuda Restante',
                          value: 'S/. ${oCcy.format(montoRestante)}',
                        ),
                        const SizedBox(height: 15),
                      ],
                      AppTextFormField(
                        controller: montoCtrl,
                        labelText: 'Monto a pagar',
                        keyboardType: TextInputType.number,
                        preffix: const Text('S/.'),
                        onChanged: (value) {
                          final montoIngresado = double.tryParse(value) ?? 0;
                          if (montoIngresado > montoRestante) {
                            setState(() {
                              restante = 0;
                            });
                          } else {
                            setState(() {
                              restante = montoRestante - montoIngresado;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      CheckboxMenuButton(
                        value: efectivo,
                        onChanged: (e) {
                          setState(() {
                            efectivo = e ?? false;
                          });
                        },
                        child: const Text('Pago en efectivo'),
                      ),
                      const Text(
                        '(Si no se selecciona el check, se considerará como pago en depósito)',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      const SizedBox(height: 15),
                      ItemPaymentLoan(
                        title: liquidar ? 'Descuento' : 'Monto restante',
                        value: 'S/. ${oCcy.format(restante)}',
                      ),
                      const SizedBox(height: 16),
                      if (!liquidar)
                        restante != 0
                            ? const Text(
                                'El monto a pagar no cubre el total de la deuda, se considerará como un pago parcial.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              )
                            : const SizedBox(),
                      const SizedBox(height: 10),
                      CustomImagePicker(
                        onImagesSelected: (photo) {
                          if (photo != null) {
                            setState(() {
                              selectedPhotosLiquidar = photo;
                            });
                          }
                        },
                        initialSelectedPhotos: selectedPhotosLiquidar,
                        limit: 1,
                      ),
                      const SizedBox(height: 20),
                      if (liquidar)
                        PrimaryButton(
                          onPressed: (loan?.ganancia != null &&
                                      montoCtrl.text != "" &&
                                      montoCtrl.text != "0" &&
                                      liquidar &&
                                      selectedPhotosLiquidar!.isNotEmpty) &&
                                  state.loansStatus != LoansStatus.loading
                              ? () {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        title: const Text('Liquidar Prestamo'),
                                        content: const Text(
                                          '¿Estás seguro que deseas liquidar el préstamo?, esta acción cerrará la deuda y no se podrá deshacer',
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            style: const ButtonStyle(
                                              backgroundColor:
                                                  MaterialStatePropertyAll(
                                                Colors.red,
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'Regresar',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            style: const ButtonStyle(
                                              backgroundColor:
                                                  MaterialStatePropertyAll(
                                                Colors.blue,
                                              ),
                                            ),
                                            onPressed: state.loansStatus !=
                                                    LoansStatus.loading
                                                ? () {
                                                    Navigator.pop(context);
                                                    context
                                                        .read<LoansBloc>()
                                                        .add(
                                                          SaveSettlementLoan(
                                                            idPrestamo: widget
                                                                    .nroPrestamo ??
                                                                0,
                                                            monto:
                                                                montoCtrl.text,
                                                            userId: authBloc
                                                                    .user?.id
                                                                    .toString() ??
                                                                '1',
                                                            codigo:
                                                                loan?.codigo ??
                                                                    0,
                                                            photos:
                                                                selectedPhotosLiquidar,
                                                            efectivo: efectivo,
                                                          ),
                                                        );
                                                  }
                                                : null,
                                            child: const Text(
                                              'Guardar',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  );
                                }
                              : null,
                          child: const Text('Liquidar'),
                        ),
                      if (!liquidar)
                        PrimaryButton(
                          onPressed: (loan?.ganancia != null &&
                                      montoCtrl.text != "" &&
                                      montoCtrl.text != "0" &&
                                      selectedPhotosLiquidar!.isNotEmpty) &&
                                  state.loansStatus != LoansStatus.loading
                              ? () {
                                  context.read<LoansBloc>().add(
                                        SavePaymentLoan(
                                          idPrestamo: widget.nroPrestamo ?? 0,
                                          monto: montoCtrl.text,
                                          userId:
                                              authBloc.user?.id.toString() ??
                                                  '1',
                                          photos: selectedPhotosLiquidar,
                                          montoRestante:
                                              montoRestante.toString(),
                                          codigo: loan?.codigo ?? 0,
                                          efectivo: efectivo,
                                        ),
                                      );
                                }
                              : null,
                          child: const Text(
                            'Registrar Pago',
                          ),
                        )
                    ],
                  ),
                ),
              );
            }
          },
        ),
        actions: [],
      ),
    );
  }
}

class ItemPaymentLoan extends StatelessWidget {
  const ItemPaymentLoan({
    super.key,
    required this.title,
    required this.value,
  });
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$title:'),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
