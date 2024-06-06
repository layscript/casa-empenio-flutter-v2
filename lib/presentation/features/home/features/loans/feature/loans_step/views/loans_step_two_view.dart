import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class LoansStepTwoView extends StatefulWidget {
  const LoansStepTwoView({super.key});

  @override
  State<LoansStepTwoView> createState() => _LoansStepTwoViewState();
}

class _LoansStepTwoViewState extends State<LoansStepTwoView> {
  // Controladores del prestamo
  final loanCodeLoanCtrl = TextEditingController();
  final amountLoanCtrl = TextEditingController();
  final deadlinesLoanCtrl = TextEditingController();
  final observationsLoanCtrl = TextEditingController();
  final startDateLoanCtrl = TextEditingController();
  final paymentDateLoanCtrl = TextEditingController();

  // Valores del prestamo
  InterestsEntity? interestRate;
  String? totalProfit;
  String? totalToPay;

  // Validaciones del prestamo
  bool isValidAmountLoan = false;
  bool isValidDeadlinesLoan = false;
  bool isValidInterestRate = false;
  //bool isValidObservationsLoan = false;

  @override
  void initState() {
    super.initState();
    // Obtener data almacenada
    getLocalData();
  }

  void getLocalData() {
    // Estado local y bloc
    final loansState = context.read<LoansStepBloc>().state;
    final preferences = context.read<Preferences>();
    final localState = preferences.getLoansPreferences;

    // Set a los controladores
    loanCodeLoanCtrl.text = loansState.codeLoans ?? localState?.codeLoans ?? '';

    startDateLoanCtrl.text =
        loansState.startDate ?? localState?.startDateTime ?? '';

    amountLoanCtrl.text = loansState.amount ?? localState?.amount ?? '';

    observationsLoanCtrl.text =
        loansState.observations ?? localState?.observations ?? '';

    deadlinesLoanCtrl.text = loansState.deadlines ?? localState?.deadline ?? '';

    // Set a las validaciones
    isValidAmountLoan = loansState.amount != null
        ? true
        : localState?.amount != null
            ? true
            : false;

    isValidDeadlinesLoan = loansState.deadlines != null
        ? true
        : localState?.deadline != null
            ? true
            : false;

    isValidInterestRate = loansState.interestRate != null
        ? true
        : localState?.interest != null
            ? true
            : false;

    /* isValidObservationsLoan = loansState.observations != null
        ? true
        : localState?.observations != null
            ? true
            : false; */

    totalProfit = localState?.totalProfit;
    totalToPay = localState?.totalToPay;

    // Set a las funciones
    parsedInterest(
      loansState.interestRate ?? localState?.interest,
      loansState.listInterests,
    );
    parsedDateTime(
      localState?.deadline ?? deadlinesLoanCtrl.text,
    );
    parsedPayData(
      localState?.amount ?? amountLoanCtrl.text,
      localState?.interest?.intereses ?? interestRate?.intereses ?? '0.00',
    );
  }

  void parsedInterest(InterestsEntity? interes, List<InterestsEntity>? list) {
    if (interes != null && list != null) {
      final response = list.firstWhere((element) => element.id == interes.id);
      setState(() {
        interestRate = response;
      });
    }
  }

  void parsedDateTime(String value) {
    final now = DateTime.now();
    final datePay = now.add(
      Duration(
        days: int.parse(value == '' ? '0' : value) - 1,
      ),
    );

    final datePayFormatt = DateFormat('dd/MM/yyyy').format(
      datePay,
    );
    paymentDateLoanCtrl.text = datePayFormatt;
  }

  void parsedPayData(String monto, String interes) {
    final monto = double.tryParse(amountLoanCtrl.text);
    final porcentaje = double.tryParse(interes);

    if (monto != null && porcentaje != null) {
      final interes = (monto * porcentaje) / 100;
      final total = monto + interes;

      final oCcy = NumberFormat("#,##0.00", "en_US");
      setState(() {
        totalToPay = oCcy.format(total);
        totalProfit = oCcy.format(interes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansState = context.watch<LoansStepBloc>().state;
    final preferences = context.read<Preferences>();
    final localState =
        preferences.getLoansPreferences ?? LoansPreferencesEntity.init();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                enabled: false,
                labelText: 'Código Prestamo',
                controller: loanCodeLoanCtrl,
                keyboardType: TextInputType.number,
                onChanged: null,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                enabled: false,
                labelText: 'Fecha',
                controller: startDateLoanCtrl,
                onChanged: null,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                preffix: const Text(
                  'S/.',
                  style: TextStyle(
                    color: AppColors.black,
                  ),
                ),
                labelText: 'Monto a prestar (requerido)',
                keyboardType: TextInputType.number,
                controller: amountLoanCtrl,
                onChanged: (e) {
                  final newState = localState.copyWith(amount: e);
                  preferences.setLoansPreferences(newState);
                },
                isValid: (value) {
                  setState(() {
                    isValidAmountLoan = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                //textDirection: TextDirection.rtl,
                labelText: 'Plazos (requerido)',
                suffix: const Text(
                  ' Dia(s)',
                  style: TextStyle(
                    color: AppColors.black,
                  ),
                ),
                keyboardType: TextInputType.number,
                controller: deadlinesLoanCtrl,
                onChanged: (value) {
                  final now = DateTime.now();
                  final datePay = now.add(
                    Duration(
                      days: int.parse(value == '' ? '0' : value) - 1,
                    ),
                  );

                  final datePayFormatt = DateFormat('dd/MM/yyyy').format(
                    datePay,
                  );

                  setState(() {
                    paymentDateLoanCtrl.text = datePayFormatt;
                  });

                  final newState = localState.copyWith(
                    deadline: value,
                    endDateTime: datePayFormatt,
                  );

                  preferences.setLoansPreferences(newState);
                },
                isValid: (value) {
                  setState(() {
                    isValidDeadlinesLoan = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppDropdownButtonFormField<InterestsEntity?>(
                value: interestRate,
                onChanged: (value) {
                  final monto = double.tryParse(amountLoanCtrl.text);
                  final porcentaje =
                      double.tryParse(value?.intereses ?? '0.00');

                  if (monto != null && porcentaje != null) {
                    final interes = (monto * porcentaje) / 100;
                    final total = monto + interes;

                    final oCcy = NumberFormat("#,##0.00", "en_US");
                    setState(() {
                      isValidInterestRate = true;
                      interestRate = value;
                      totalToPay = oCcy.format(total);
                      totalProfit = oCcy.format(interes);
                    });

                    final newState = localState.copyWith(
                      interest: value,
                      totalToPay: oCcy.format(total),
                      totalProfit: oCcy.format(interes),
                    );
                    preferences.setLoansPreferences(newState);
                  }
                },
                labelText: 'Tasa de Interes (requerido)',
                items: loansState.listInterests != null
                    ? loansState.listInterests!
                        .map(
                          (e) => DropdownMenuItem<InterestsEntity?>(
                            value: e,
                            child: Text(e.intereses),
                          ),
                        )
                        .toList()
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                enabled: false,
                labelText: 'Fecha de Pago',
                controller: paymentDateLoanCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
                onChanged: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Observaciones (opcional)',
          controller: observationsLoanCtrl,
          /*  isValid: (value) {
            setState(() {
              isValidObservationsLoan = value;
            });
          }, */
          onChanged: (e) {
            final newState = localState.copyWith(observations: e);
            preferences.setLoansPreferences(newState);
          },
          /* validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          }, */
        ),
        const SizedBox(height: 15),
        if (totalProfit != null && totalToPay != null) ...[
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Ganancia: S/. $totalProfit',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Total a Pagar: S/. $totalToPay',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],
        const SizedBox(height: 15),
        SecondaryButton(
          onPressed: () {
            context.read<LoansStepBloc>().add(
                  SaveSecondStepOne(
                    index: 0,
                    amount: amountLoanCtrl.text,
                    deadlines: deadlinesLoanCtrl.text,
                    interest: interestRate,
                    endDateTime: paymentDateLoanCtrl.text,
                    observations: observationsLoanCtrl.text,
                  ),
                );
          },
          child: const Text('Volver'),
        ),
        const SizedBox(height: 15),
        PrimaryButton(
          onPressed: isValidAmountLoan &&
                  isValidDeadlinesLoan &&
                  isValidInterestRate /* &&
                  isValidObservationsLoan */
              ? () {
                  context.read<LoansStepBloc>().add(
                        SaveSecondStepOne(
                          index: 2,
                          amount: amountLoanCtrl.text,
                          deadlines: deadlinesLoanCtrl.text,
                          interest: interestRate,
                          endDateTime: paymentDateLoanCtrl.text,
                          observations: observationsLoanCtrl.text,
                        ),
                      );
                }
              : null,
          child: const Text('Continuar para guardar'),
        )
      ],
    );
  }
}
