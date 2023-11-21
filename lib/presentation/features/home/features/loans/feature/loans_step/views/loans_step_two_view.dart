import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepTwoView extends StatelessWidget {
  const LoansStepTwoView({super.key});

  @override
  Widget build(BuildContext context) {
    final loansState = context.watch<LoansStepBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Código Prestamo',
                initialValue: loansState.codeLoans,
                keyboardType: TextInputType.number,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeCodeLoans(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Fecha',
                initialValue: loansState.startDate,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeStartDate(value: e),
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
              child: AppTextFormField(
                labelText: 'Monto a prestar',
                initialValue: loansState.amount,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeAmount(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Plazos',
                initialValue: loansState.deadlines,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeDeadLines(value: e),
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
              child: AppTextFormField(
                labelText: 'Tasa de Interes',
                initialValue: loansState.interestRate,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeInterestRate(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Fecha de Pago',
                initialValue: loansState.paymentDate,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangePaymentRate(value: e),
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
        AppTextFormField(
          labelText: 'Observaciones',
          initialValue: loansState.observations,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangeObservations(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        Text('Ganancia: '),
        Text('Total a Pagar: '),
        const SizedBox(height: 15),
        SecondaryButton(
          onPressed: () => context.read<LoansStepBloc>().add(
                const ChangeIndexLoans(
                  index: 0,
                ),
              ),
          child: Text('Volver'),
        ),
        const SizedBox(height: 15),
        PrimaryButton(
          onPressed: loansState.canRegisterLoans
              ? () => context.read<LoansStepBloc>().add(
                    const ChangeIndexLoans(
                      index: 2,
                    ),
                  )
              : null,
          child: Text('Continuar'),
        )
      ],
    );
  }
}
