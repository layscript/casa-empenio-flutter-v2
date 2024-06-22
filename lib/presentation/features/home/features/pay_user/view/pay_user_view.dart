import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/buttons/buttons.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/pay_user/widgets/add_pay_user_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PayUserView extends StatefulWidget {
  const PayUserView({super.key});

  @override
  State<PayUserView> createState() => _PayUserViewState();
}

class _PayUserViewState extends State<PayUserView> {
  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();

    return BlocProvider(
      lazy: false,
      create: (context) => PayUserBloc(
        motionRepository: context.read(),
        cajaRepository: context.read(),
        preferences: context.read(),
      )
        ..add(const GetPayExpenses(end: null, start: null))
        ..add(GetCashPayExpensesStatus()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<PayUserBloc, PayUserState>(
            listener: (context, state) {
              if (state.isPaymentsFailure) {
                Navigator.pop(context);
                ErrorSnackbar.show(context, state.error ?? '');
              }

              if (state.isPaymentsSuccess) {
                Navigator.pop(context, true);
                SuccessSnackbar.show(context, 'Agregado correctamente');
              }

              if (state.openBox == true) {
                //if (false) {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return const AlertGoToCaja();
                  },
                ).then((value) {
                  homeBloc.add(GoToOpenCaja());
                });
              }
            },
            builder: (context, state) {
              switch (state.payUserStatus) {
                case PayUserStatus.initial || PayUserStatus.loading:
                  return const ButtonStateLoading();

                case PayUserStatus.error || PayUserStatus.failure:
                  return ButtonStateError(
                    onPressed: () {
                      context.read<PayUserBloc>()
                        ..add(const GetPayExpenses(
                          end: null,
                          start: null,
                        ))
                        ..add(GetCashPayExpensesStatus());
                    },
                  );

                case PayUserStatus.loaded || PayUserStatus.success:
                  final payUserBloc = context.read<PayUserBloc>();
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
                                    'Lista de Pagos a Personales',
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.calendar_today,
                                  ),
                                  title: FittedBox(
                                    child: Text(
                                      'Desde: ${DateFormat('dd/MM/yyyy').format(state.startExpenses)} Hasta: ${DateFormat('dd/MM/yyyy').format(state.endExpenses)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final result = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2022, 1, 1),
                                        lastDate: DateTime(2030, 12, 31),
                                        currentDate: DateTime.now(),
                                        saveText: 'Done',
                                      );

                                      if (result != null && mounted) {
                                        payUserBloc.add(
                                          GetPayExpenses(
                                            start: result.start,
                                            end: result.end,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today),
                                  ),
                                ),
                                if (state.listPayments != null)
                                  ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(
                                      height: 10,
                                    ),
                                    shrinkWrap: true,
                                    itemCount: state.listPayments!.length,
                                    itemBuilder: (context, index) {
                                      final expense =
                                          state.listPayments![index];

                                      return ExpansionTile(
                                        title: Text(
                                          'Monto: s/. ${expense.monto}',
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Fecha: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(expense.createdAt ?? '').toLocal())}',
                                        ),
                                        childrenPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20),
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'Tipo:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text('${expense.tipo?.codigo}')
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Text(
                                                'Observaciones: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text('${expense.observaciones}')
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                        ],
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
                              child: PrimaryButton(
                                onPressed: () async {
                                  final result = await showDialog<bool?>(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<PayUserBloc>(),
                                        child: const AddPayUserDialog(),
                                      );
                                    },
                                  );

                                  if (result != null && mounted) {
                                    context
                                        .read<PayUserBloc>()
                                        .add(const GetPayExpenses(
                                          end: null,
                                          start: null,
                                        ));
                                  }
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FaIcon(FontAwesomeIcons.circlePlus),
                                    SizedBox(width: 10),
                                    Text('Registrar Pago'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
