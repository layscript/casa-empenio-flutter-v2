import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepTwoView extends StatelessWidget {
  const LoansStepTwoView({super.key});

  @override
  Widget build(BuildContext context) {
    final loansStepBloc = context.read<LoansStepBloc>();
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
              child: BlocBuilder<LoansStepBloc, LoansStepState>(
                builder: (context, state) {
                  return AppTextFormField(
                    enabled: false,
                    labelText: 'Código Prestamo',
                    initialValue: state.codeLoans ?? localState.codeLoans,
                    keyboardType: TextInputType.number,
                    onChanged: null,
                    validator: (value) {
                      if (value!.isEmpty) return 'Campo Requerido';
                      return null;
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BlocBuilder<LoansStepBloc, LoansStepState>(
                builder: (context, state) {
                  return AppTextFormField(
                    enabled: false,
                    labelText: 'Fecha',
                    initialValue: state.startDate ?? localState.startDateTime,
                    onChanged: null,
                    validator: (value) {
                      if (value!.isEmpty) return 'Campo Requerido';
                      return null;
                    },
                  );
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
                initialValue: localState.amount,
                onChanged: (e) => loansStepBloc.add(ChangeAmount(value: e)),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Plazos (requerido)',
                suffix: const Text(
                  ' Dia(s)',
                  style: TextStyle(
                    color: AppColors.black,
                  ),
                ),
                keyboardType: TextInputType.number,
                initialValue: localState.deadline,
                onChanged: (e) => loansStepBloc.add(
                  ChangeDeadLines(
                    value: e,
                  ),
                ),
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
              child: BlocBuilder<LoansStepBloc, LoansStepState>(
                builder: (context, state) {
                  return AppDropdownButtonFormField<InterestsEntity?>(
                    value: state.interestRate ?? localState.interest,
                    onChanged: (e) => loansStepBloc.add(
                      ChangeInterestRate(
                        value: e,
                      ),
                    ),
                    labelText: 'Tasa de Interes (requerido)',
                    items: state.listInterests != null
                        ? state.listInterests!
                            .map(
                              (e) => DropdownMenuItem<InterestsEntity?>(
                                value: e,
                                child: Text(e.intereses),
                              ),
                            )
                            .toList()
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BlocBuilder<LoansStepBloc, LoansStepState>(
                builder: (context, state) {
                  return AppTextFormField(
                    enabled: false,
                    labelText: 'Fecha de Pago',
                    initialValue: state.paymentDate ?? localState.endDateTime,
                    validator: (value) {
                      if (value!.isEmpty) return 'Campo Requerido';
                      return null;
                    },
                    onChanged: null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Observaciones (opcional)',
          initialValue: localState.observations,
          onChanged: (e) => loansStepBloc.add(
            ChangeObservations(
              value: e,
            ),
          ),
        ),
        const SizedBox(height: 15),
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            final temp1 = state.totalProfit ?? localState.totalProfit;
            final temp2 = state.totalToPay ?? localState.totalToPay;
            if (temp1 != null && temp2 != null) {
              return SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Ganancia: S/. $temp1',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Total a Pagar: S/. $temp2',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
        const SizedBox(height: 15),
        SecondaryButton(
          onPressed: () {
            loansStepBloc
              ..add(const SaveTempDataLoans())
              ..add(const SaveSecondStepOne(index: 0));
          },
          child: const Text('Volver'),
        ),
        const SizedBox(height: 15),
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            final codeLoansState =
                (state.codeLoans != null && state.codeLoans != '') ||
                    localState.codeLoans != null;

            final startTimeState =
                (state.startDate != null && state.startDate != '') ||
                    localState.startDateTime != null;

            final amountState = (state.amount != null && state.amount != '') ||
                localState.amount != null;

            final deadlinesState =
                (state.deadlines != null && state.deadlines != '') ||
                    localState.deadline != null;

            final interestState =
                (state.interestRate != null) || localState.interest != null;

            return PrimaryButton(
              onPressed: codeLoansState &&
                      startTimeState &&
                      amountState &&
                      deadlinesState &&
                      interestState
                  ? () {
                      loansStepBloc
                        ..add(const SaveTempDataLoans())
                        ..add(const SaveSecondStepOne(index: 2));
                    }
                  : null,
              child: const Text('Continuar para guardar'),
            );
          },
        ),
        /* */
      ],
    );
  }
}
