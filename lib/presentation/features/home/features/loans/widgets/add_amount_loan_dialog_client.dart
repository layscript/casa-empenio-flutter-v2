import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddAmountLoanDialogClient extends StatefulWidget {
  const AddAmountLoanDialogClient({
    super.key,
    required this.nroPrestamo,
  });
  final int? nroPrestamo;

  @override
  State<AddAmountLoanDialogClient> createState() =>
      _AddAmountLoanDialogClientState();
}

class _AddAmountLoanDialogClientState extends State<AddAmountLoanDialogClient> {
  @override
  void initState() {
    super.initState();
    if (widget.nroPrestamo != null) {
      context.read<LoansBloc>().add(GetDetailsLoan(widget.nroPrestamo!));
    }
  }

  final montoCtrl = TextEditingController();
  final obsCtrl = TextEditingController();
  bool isMontoValid = false;
  List<XFile>? selectedPhotosLiquidar = [];

  @override
  Widget build(BuildContext context) {
    final preferences = context.read<Preferences>();
    final loansState = context.watch<LoansBloc>().state;

    return AbsorbPointer(
      absorbing: loansState.loansStatus == LoansStatus.addAmountLoading,
      child: GestureDetector(
        onTap: () => Keyboard.unfocus(context),
        child: AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 20,
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          content: BlocConsumer<LoansBloc, LoansState>(
            listener: (context, state) {
              if (state.isLoansAddAmountLoading) {
                OverlayLoader.show(context);
              } else {
                OverlayLoader.hide();
                if (state.isLoansAddAmountSuccess) {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'Monto Agregado',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                        content: const Text(
                            'El monto se ha registrado correctamente'),
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

                if (state.isLoansAddAmountError) {
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
                        content: const Text('Vuelve a intentarlo de nuevo'),
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
                return SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Agregar Aumento',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                          'Aumento Total Prestado: S/. ${oCcy.format(double.parse(loan?.monto ?? '0.00'))}'),
                      const SizedBox(height: 20),
                      AppTextFormField(
                        keyboardType: TextInputType.number,
                        labelText: 'Monto a agregar',
                        controller: montoCtrl,
                        validator: (value) {
                          if (value!.isEmpty) return 'Campo requerido';
                          return null;
                        },
                        isValid: (value) => setState(() {
                          isMontoValid = value;
                        }),
                      ),
                      const SizedBox(height: 20),
                      AppTextFormField(
                        labelText: 'Observación',
                        controller: obsCtrl,
                      ),
                      const SizedBox(height: 20),
                      CustomImagePicker(
                        onImagesSelected: (photos) {
                          setState(() {
                            selectedPhotosLiquidar = photos;
                          });
                        },
                        initialSelectedPhotos: selectedPhotosLiquidar,
                        limit: 1,
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: !isMontoValid || selectedPhotosLiquidar!.isEmpty
                      ? null
                      : () {
                          context.read<LoansBloc>().add(
                                AddAmountLoan(
                                  idPrestamo: widget.nroPrestamo ?? 0,
                                  monto: double.parse(montoCtrl.text),
                                  obs: obsCtrl.text,
                                  userId:
                                      preferences.token?.id.toString() ?? '0',
                                  photos: selectedPhotosLiquidar,
                                ),
                              );
                        },
                  child: const Text(
                    'Agregar',
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
