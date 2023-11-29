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
    final loansState = context.watch<LoansStepBloc>().state;

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
                controller: TextEditingController(text: loansState.codeLoans),
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
                controller: TextEditingController(text: loansState.startDate),
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
                labelText: 'Monto a prestar',
                keyboardType: TextInputType.number,
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
                textDirection: TextDirection.rtl,
                labelText: 'Plazos',
                suffix: const Text(
                  ' Dia(s)',
                  style: TextStyle(
                    color: AppColors.black,
                  ),
                ),
                initialValue: loansState.deadlines,
                keyboardType: TextInputType.number,
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
              child: AppDropdownButtonFormField<InterestsEntity>(
                value: loansState.interestRate,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeInterestRate(
                        value: e,
                      ),
                    ),
                labelText: 'Tasa de Interes',
                items: loansState.listInterests != null
                    ? loansState.listInterests!
                        .map(
                          (e) => DropdownMenuItem<InterestsEntity>(
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
                controller: TextEditingController(text: loansState.paymentDate),
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
        //TODO:: Mejorar diseño aqui
        if (loansState.totalProfit != null &&
            loansState.totalToPay != null) ...[
          Text('Ganancia: ${loansState.totalProfit}'),
          Text('Total a Pagar: ${loansState.totalToPay}'),
        ],
        const SizedBox(height: 15),
        SecondaryButton(
          onPressed: () => context.read<LoansStepBloc>().add(
                const ChangeIndexLoans(
                  index: 0,
                ),
              ),
          child: const Text('Volver'),
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
          child: const Text('Continuar'),
        )
      ],
    );
  }
}
