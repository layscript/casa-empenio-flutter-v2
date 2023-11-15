import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepOne extends StatelessWidget {
  const LoansStepOne({super.key});

  @override
  Widget build(BuildContext context) {
    final loansState = context.watch<LoansBloc>().state;

    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: AppTextFormField(
                  initialValue: loansState.document,
                  labelText: 'DNI',
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  onChanged: (e) => context.read<LoansBloc>().add(
                        ChangeDocument(value: e),
                      ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo Requerido';
                    if (value.length < 8) return 'Ingresar 8 Dígitos';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextFormField(
                  labelText: 'Nombres',
                  initialValue: loansState.fullNames,
                  onChanged: (e) => context.read<LoansBloc>().add(
                        ChangeFullNames(value: e),
                      ),
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo Requerido';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppTextFormField(
                  maxLength: 9,
                  labelText: 'Celular',
                  initialValue: loansState.phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (e) => context.read<LoansBloc>().add(
                        ChangePhone(value: e),
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
                  labelText: 'Apellidos',
                  initialValue: loansState.fullLastNames,
                  onChanged: (e) => context.read<LoansBloc>().add(
                        ChangeFullLastNames(value: e),
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
            labelText: 'Correo Electrónico',
            keyboardType: TextInputType.emailAddress,
            initialValue: loansState.email,
            inputFormatters: removeBlankSpaces,
            onChanged: (e) => context.read<LoansBloc>().add(
                  ChangeEmail(value: e),
                ),
            validator: (value) {
              if (value!.isEmpty) return 'Campo Requerido';
              if (!validatorEmail(value)) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 15),
          AppTextFormField(
            labelText: 'Domicilio',
            initialValue: loansState.home,
            onChanged: (e) => context.read<LoansBloc>().add(
                  ChangeHome(value: e),
                ),
            validator: (value) {
              if (value!.isEmpty) return 'Campo Requerido';
              return null;
            },
          ),
          const SizedBox(height: 15),
          PrimaryButton(
            onPressed: loansState.canRegisterClient
                ? () => context.read<LoansBloc>().add(
                      const ChangeIndexLoans(
                        index: 1,
                      ),
                    )
                : null,
            child: const Text('Continuar'),
          )
        ],
      ),
    );
  }
}
