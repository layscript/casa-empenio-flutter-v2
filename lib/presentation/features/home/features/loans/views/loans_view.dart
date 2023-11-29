// ignore_for_file: prefer_is_empty

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/buttons/buttons.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class LoansView extends StatefulWidget {
  const LoansView({super.key});

  @override
  State<LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<LoansView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoansBloc(
        customerRepository: context.read(),
        loansRepository: context.read(),
      ),
      child: Builder(
        builder: (context) {
          return BlocConsumer<LoansBloc, LoansState>(
              listener: (context, state) {
            if (state.isLoansLoading) {
              OverlayLoader.show(context);
            } else {
              OverlayLoader.hide();
              if (state.isLoansError) {
                ErrorSnackbar.show(context, state.error ?? '');
              }
            }
          }, builder: (context, state) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: MediaQuery.of(context).size.height * 0.9,
                    padding: const EdgeInsets.only(
                      bottom: 120,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'Lista de Préstamos',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: Column(
                              children: [
                                const SearchLoansClient(),
                                const SizedBox(height: 15),
                                if (state.customer != null)
                                  Row(
                                    children: [
                                      const Text(
                                        'Cliente:',
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          state.fullNames(),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                const Divider(),
                              ],
                            ),
                          ),
                          if (state.customer?.prestamos != null)
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(
                                height: 10,
                              ),
                              shrinkWrap: true,
                              itemCount: state.customer?.prestamos?.length ?? 0,
                              itemBuilder: (context, index) {
                                final oCcy = NumberFormat("#,##0.00", "en_US");

                                final prestamo =
                                    state.customer?.prestamos?[index];

                                final montoFinal = oCcy
                                    .format(double.parse(
                                            prestamo?.ganancia ?? '0.00') +
                                        double.parse(prestamo?.monto ?? '0.00'))
                                    .toString();

                                final auth = context.read<AuthBloc>().state
                                    as Authenticated;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: prestamo?.estado == 'CANCELADO'
                                        ? Colors.red[50]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      'Cod:. ${prestamo?.codigo.toString().padLeft(6, '0')} - s/.$montoFinal',
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    subtitle: prestamo?.fecha != null
                                        ? Text(
                                            '${state.formattedDate(
                                              prestamo!.fecha!,
                                            )} ${prestamo.estado == 'CANCELADO' ? '- CANCELADO' : ''}',
                                            maxLines: 3,
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        //Visualizar
                                        SizedBox(
                                          height: 38,
                                          width: 38,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (_) {
                                                  return BlocProvider.value(
                                                    value: context
                                                        .read<LoansBloc>(),
                                                    child: ShowInfoClientLoans(
                                                      nroPrestamo:
                                                          prestamo?.codigo,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.remove_red_eye_outlined,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        if (auth.user.role?.id != 2)
                                          //Editar
                                          SizedBox(
                                            height: 38,
                                            width: 38,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                if (prestamo?.cerrado ==
                                                    false) {
                                                  // open modal editar
                                                } else {
                                                  // open modal nuevo
                                                }
                                              },
                                              icon: Icon(
                                                prestamo?.cerrado == false
                                                    ? Icons.edit
                                                    : Icons.new_label,
                                                color:
                                                    prestamo?.cerrado == false
                                                        ? Colors.blue
                                                        : Colors.purple,
                                              ),
                                            ),
                                          ),
                                        if (auth.user.role?.id == 2 &&
                                            prestamo?.cerrado == true)
                                          SizedBox(
                                            height: 38,
                                            width: 38,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                // TODO:: falta validar
                                              },
                                              icon: const Icon(
                                                Icons.new_label,
                                                color: Colors.purple,
                                              ),
                                            ),
                                          ),
                                        if (prestamo?.cerrado == false)
                                          // Pagar prestamo
                                          SizedBox(
                                            height: 38,
                                            width: 38,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                final result =
                                                    await showDialog<bool>(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (_) {
                                                    return BlocProvider.value(
                                                      value: context
                                                          .read<LoansBloc>(),
                                                      child:
                                                          PaymentLoanDialogClient(
                                                        nroPrestamo:
                                                            prestamo?.codigo,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.payments_outlined,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        if (prestamo?.cerrado == false)
                                          // Agregar monto
                                          SizedBox(
                                            height: 38,
                                            width: 38,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                final result =
                                                    await showDialog<bool>(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (_) {
                                                    return BlocProvider.value(
                                                      value: context
                                                          .read<LoansBloc>(),
                                                      child:
                                                          AddAmountLoanDialogClient(
                                                        nroPrestamo:
                                                            prestamo?.codigo,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              icon: Icon(
                                                Icons.add_card,
                                                color: Colors.red[400],
                                              ),
                                            ),
                                          ),
                                        if (prestamo?.cerrado == true &&
                                            prestamo?.estado != 'CANCELADO')
                                          SizedBox(
                                            height: 38,
                                            width: 38,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                if (prestamo?.boleta == null) {
                                                  // Abrir modal facturacion
                                                  // prestamo -> codigo
                                                  // cliente -> dni

                                                  final dniCustomer =
                                                      state.customer?.dni;
                                                  final result =
                                                      await showDialog<bool>(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (_) {
                                                      return BlocProvider.value(
                                                        value: context
                                                            .read<LoansBloc>(),
                                                        child:
                                                            ShowDialogBillingLoan(
                                                          nroPrestamo:
                                                              prestamo?.codigo,
                                                          dniCustomer:
                                                              dniCustomer,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  // Abrir excel - verde
                                                  Navigator.push(context,
                                                      MaterialPageRoute(
                                                    builder: (context) {
                                                      return PdfPreviewFacturaPage(
                                                        url: prestamo
                                                                ?.boleta?.pdf ??
                                                            '',
                                                        id: prestamo?.codigo ??
                                                            0,
                                                        tipo: 'prestamo',
                                                        notaCredito: prestamo
                                                            ?.notaCredito,
                                                      );
                                                    },
                                                  ));
                                                }
                                              },
                                              icon: Icon(
                                                Icons.description,
                                                color: prestamo?.boleta == null
                                                    ? Colors.blue
                                                    : prestamo?.notaCredito
                                                                ?.length ==
                                                            0
                                                        ? Colors.green
                                                        : Colors.red[400],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: null,
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: defaultBoxShadow,
                      ),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SecondaryButton(
                              onPressed: () async {
                                final result =
                                    await showDialog<CustomerEntity?>(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return const ShowDialogClients();
                                  },
                                );

                                if (result != null && mounted) {
                                  context.read<LoansBloc>().add(
                                        GetLoansByDni(
                                          value: result.dni!,
                                        ),
                                      );
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.searchengin),
                                  SizedBox(width: 10),
                                  Text('Ver Clientes'),
                                ],
                              ),
                            ),
                            PrimaryButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  LoansStepView.route,
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.circlePlus),
                                  SizedBox(width: 10),
                                  Text('Agregar Préstamo'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          });
        },
      ),
    );
  }
}
