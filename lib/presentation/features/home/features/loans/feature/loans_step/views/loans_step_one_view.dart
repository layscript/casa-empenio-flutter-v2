import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepOneView extends StatelessWidget {
  const LoansStepOneView({super.key});

  @override
  Widget build(BuildContext context) {
    final loansState = context.watch<LoansStepBloc>().state;

    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: AppTextFormField(
                  initialValue: loansState.documentClient,
                  labelText: 'DNI',
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangeDocumentClient(value: e),
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
                  initialValue: loansState.fullNamesClient,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangeFullNamesClient(value: e),
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
                  initialValue: loansState.phoneClient,
                  keyboardType: TextInputType.phone,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangePhoneClient(value: e),
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
                  initialValue: loansState.fullLastNamesClient,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangeFullLastNamesClient(value: e),
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
            initialValue: loansState.emailClient,
            inputFormatters: removeBlankSpaces,
            onChanged: (e) => context.read<LoansStepBloc>().add(
                  ChangeEmailClient(value: e),
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
            initialValue: loansState.homeClient,
            onChanged: (e) => context.read<LoansStepBloc>().add(
                  ChangeHomeClient(value: e),
                ),
            validator: (value) {
              if (value!.isEmpty) return 'Campo Requerido';
              return null;
            },
          ),
          const SizedBox(height: 15),
          AppCheckbox(
            labelText: 'Agregar Aval',
            onChanged: (value) => context.read<LoansStepBloc>().add(
                  ChangeHasClientAval(
                    value: value,
                  ),
                ),
            value: loansState.isAval,
          ),
          if (loansState.isAval == true) ...[
            const _AddClientAval(),
          ],
          const SizedBox(height: 15),
          PrimaryButton(
            onPressed: loansState.canRegisterClient
                ? () => context.read<LoansStepBloc>().add(
                      const ChangeIndexLoans(
                        index: 1,
                      ),
                    )
                : null,
            child: const Text('Continuar'),
          ),
          const SizedBox(height: 35),
        ],
      ),
    );
  }
}

class _AddClientAval extends StatelessWidget {
  const _AddClientAval();

  @override
  Widget build(BuildContext context) {
    final loansState = context.watch<LoansStepBloc>().state;

    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          const SizedBox(
            width: double.infinity,
            child: Center(
              child: Text(
                'Datos del Aval',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: AppTextFormField(
                  initialValue: loansState.documentAval,
                  labelText: 'DNI',
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangeDocumentAval(value: e),
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
                  initialValue: loansState.fullNamesAval,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangeFullNamesAval(value: e),
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
                  initialValue: loansState.phoneAval,
                  keyboardType: TextInputType.phone,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangePhoneAval(value: e),
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
                  initialValue: loansState.fullLastNamesAval,
                  onChanged: (e) => context.read<LoansStepBloc>().add(
                        ChangeFullLastNamesAval(value: e),
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
            initialValue: loansState.emailAval,
            inputFormatters: removeBlankSpaces,
            onChanged: (e) => context.read<LoansStepBloc>().add(
                  ChangeEmailAval(value: e),
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
            initialValue: loansState.homeAval,
            onChanged: (e) => context.read<LoansStepBloc>().add(
                  ChangeHomeAval(value: e),
                ),
            validator: (value) {
              if (value!.isEmpty) return 'Campo Requerido';
              return null;
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
