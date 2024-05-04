import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/expenses/bloc/expenses_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/expenses/widgets/add_expense_dialog.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();

    return BlocProvider(
      lazy: false,
      create: (context) => ExpensesBloc(
        expensesRepository: context.read(),
        cajaRepository: context.read(),
      )
        ..add(
          const GetExpenses(
            end: null,
            start: null,
          ),
        )
        ..add(GetCashExpensesStatus()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<ExpensesBloc, ExpensesState>(
            listener: (context, state) {
              if (state.openBox == true) {
                //if (false) {
                showDialog<bool>(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return const AlertGoToCaja();
                  },
                ).then((value) {
                  homeBloc.add(GoToOpenCaja());
                });
              }

              if (state.isExpensesFailure) {
                Navigator.pop(context);
                ErrorSnackbar.show(context, state.error ?? '');
              }

              if (state.isExpensesSuccess) {
                Navigator.pop(context, true);
                SuccessSnackbar.show(context, 'Agregado correctamente');
              }
            },
            builder: (context, state) {
              switch (state.expensesStatus) {
                case ExpensesStatus.initial || ExpensesStatus.loading:
                  return const ButtonStateLoading();

                case ExpensesStatus.error || ExpensesStatus.failure:
                  return ButtonStateError(
                    onPressed: () {
                      context.read<ExpensesBloc>()
                        ..add(
                          const GetExpenses(
                            end: null,
                            start: null,
                          ),
                        )
                        ..add(GetCashExpensesStatus());
                    },
                  );

                case ExpensesStatus.loaded || ExpensesStatus.success:
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
                                    'Lista de Gastos',
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
                                        context.read<ExpensesBloc>().add(
                                              GetExpenses(
                                                start: result.start,
                                                end: result.end,
                                              ),
                                            );
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today),
                                  ),
                                ),
                                if (state.listExpenses != null)
                                  ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(
                                      height: 10,
                                    ),
                                    shrinkWrap: true,
                                    itemCount: state.listExpenses!.length,
                                    itemBuilder: (context, index) {
                                      final expense =
                                          state.listExpenses![index];
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
                                          /* const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Text(
                                              'Descripción: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text('${expense.tipo?.descripcion}')
                                          ],
                                        ), */
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
                                const SizedBox(height: 35),
                              ],
                            ),
                          ),
                        ),
                        // Total de Gastos anclado
                        if (state.totalGastos != null)
                          Positioned(
                            bottom: 120,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlack,
                                boxShadow: defaultBoxShadow,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total de Gastos: s/. ${state.totalGastos?.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: AppColors.white,
                                    ),
                                  ),
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
                                        value: context.read<ExpensesBloc>(),
                                        child: const AddExpenseDialog(),
                                      );
                                    },
                                  );

                                  if (result != null && mounted) {
                                    context.read<ExpensesBloc>().add(
                                          const GetExpenses(
                                            end: null,
                                            start: null,
                                          ),
                                        );
                                  }
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FaIcon(FontAwesomeIcons.circlePlus),
                                    SizedBox(width: 10),
                                    Text('Agregar Gasto'),
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
