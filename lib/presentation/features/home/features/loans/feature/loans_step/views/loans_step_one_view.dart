import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepOneView extends StatelessWidget {
  const LoansStepOneView({super.key});

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
              child: AppTextFormField(
                initialValue: localState.documentClient,
                labelText: 'DNI (requerido)',
                keyboardType: TextInputType.number,
                maxLength: 8,
                onChanged: (e) => loansStepBloc.add(
                  ChangeDocumentClient(
                    value: e,
                  ),
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
              child: BlocBuilder<LoansStepBloc, LoansStepState>(
                builder: (context, state) {
                  return AppTextFormField(
                    labelText: 'Nombres (requerido)',
                    initialValue:
                        state.fullNamesClient ?? localState.fullNamesClient,
                    onChanged: (e) => loansStepBloc.add(
                      ChangeFullNamesClient(
                        value: e,
                      ),
                    ),
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
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                maxLength: 9,
                labelText: 'Celular (requerido)',
                preffix: const Text('(+51)'),
                keyboardType: TextInputType.phone,
                initialValue: localState.phoneClient,
                onChanged: (e) => loansStepBloc.add(
                  ChangePhoneClient(
                    value: e,
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BlocBuilder<LoansStepBloc, LoansStepState>(
                builder: (context, state) {
                  return AppTextFormField(
                    labelText: 'Apellidos (requerido)',
                    initialValue: state.fullLastNamesClient ??
                        localState.fullLastNamesClient,
                    validator: (value) {
                      if (value!.isEmpty) return 'Campo Requerido';
                      return null;
                    },
                    onChanged: (e) => loansStepBloc.add(
                      ChangeFullLastNamesClient(
                        value: e,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Correo Electrónico (opcional)',
          keyboardType: TextInputType.emailAddress,
          inputFormatters: removeBlankSpaces,
          initialValue: localState.emailClient,
          onChanged: (e) => loansStepBloc.add(
            ChangeEmailClient(
              value: e,
            ),
          ),
        ),
        const SizedBox(height: 15),
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            return AppTextFormField(
              labelText: 'Domicilio (requerido)',
              initialValue: state.homeClient ?? localState.domicilioClient,
              onChanged: (e) => loansStepBloc.add(
                ChangeHomeClient(value: e),
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Campo Requerido';
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 15),
        CustomImagePicker(
          onImagesSelected: (e) => loansStepBloc.add(
            ChangePhotosClient(
              photosClient: e,
            ),
          ),
          initialSelectedPhotos: localState.imagesClient,
          limit: 2,
        ),
        const SizedBox(height: 15),
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            return AppCheckbox(
              labelText: 'Agregar Aval',
              value: state.isAval,
              onChanged: (e) => loansStepBloc.add(
                ChangeHasClientAval(
                  value: e,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            if (state.isAval == true) {
              return Column(
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
                          labelText: 'DNI (requerido)',
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          initialValue: localState.documentAval,
                          onChanged: (e) => loansStepBloc.add(
                            ChangeDocumentAval(
                              value: e,
                            ),
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
                        child: BlocBuilder<LoansStepBloc, LoansStepState>(
                          builder: (context, state) {
                            return AppTextFormField(
                              labelText: 'Nombres (requerido)',
                              initialValue: state.fullNamesAval ??
                                  localState.fullNamesAval,
                              onChanged: (e) => loansStepBloc.add(
                                ChangeFullNamesAval(
                                  value: e,
                                ),
                              ),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          maxLength: 9,
                          labelText: 'Celular (requerido)',
                          preffix: const Text('(+51)'),
                          initialValue: localState.phoneAval,
                          keyboardType: TextInputType.phone,
                          onChanged: (e) => loansStepBloc.add(
                            ChangePhoneAval(
                              value: e,
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return 'Campo Requerido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BlocBuilder<LoansStepBloc, LoansStepState>(
                          builder: (context, state) {
                            return AppTextFormField(
                              labelText: 'Apellidos (requerido)',
                              initialValue: state.fullLastNamesAval ??
                                  localState.fullLastNamesAval,
                              onChanged: (e) => loansStepBloc.add(
                                ChangeFullLastNamesAval(
                                  value: e,
                                ),
                              ),
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
                  AppTextFormField(
                    labelText: 'Correo Electrónico (opcional)',
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: removeBlankSpaces,
                    initialValue: localState.emailAval,
                    onChanged: (e) => loansStepBloc.add(
                      ChangeEmailAval(value: e),
                    ),
                  ),
                  const SizedBox(height: 15),
                  BlocBuilder<LoansStepBloc, LoansStepState>(
                    builder: (context, state) {
                      return AppTextFormField(
                        labelText: 'Domicilio (requerido)',
                        initialValue:
                            state.homeAval ?? localState.domicilioAval,
                        onChanged: (e) =>
                            loansStepBloc.add(ChangeHomeAval(value: e)),
                        validator: (value) {
                          if (value!.isEmpty) return 'Campo Requerido';
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  CustomImagePicker(
                    onImagesSelected: (e) => loansStepBloc.add(
                      ChangePhotosAval(
                        photosAval: e,
                      ),
                    ),
                    initialSelectedPhotos: localState.imagesAval,
                    limit: 2,
                  ),
                  const SizedBox(height: 15),
                ],
              );
            }
            return const SizedBox();
          },
        ),
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            return PrimaryButton(
              onPressed: (state.documentClient?.isNotEmpty ??
                          false || localState.documentClient != null) &&
                      (state.fullNamesClient?.isNotEmpty ??
                          false || localState.fullNamesClient != null) &&
                      (state.fullLastNamesClient?.isNotEmpty ??
                          false || localState.fullLastNamesClient != null) &&
                      (state.phoneClient?.isNotEmpty ??
                          false || localState.phoneClient != null) &&
                      (state.homeClient?.isNotEmpty ??
                          false || localState.domicilioClient != null)
                  ? state.isAval == true
                      ? (state.documentAval?.isNotEmpty ??
                                  false || localState.documentAval != null) &&
                              (state.fullNamesAval?.isNotEmpty ??
                                  false || localState.fullNamesAval != null) &&
                              (state.fullLastNamesAval?.isNotEmpty ??
                                  false ||
                                      localState.fullLastNamesAval != null) &&
                              (state.phoneAval?.isNotEmpty ??
                                  false || localState.phoneAval != null) &&
                              (state.homeAval?.isNotEmpty ??
                                  false || localState.domicilioAval != null)
                          ? () {
                              loansStepBloc
                                ..add(const SaveTempDataLoans())
                                ..add(const SaveFirstStepOne());
                            }
                          : null
                      : () {
                          loansStepBloc
                            ..add(const SaveTempDataLoans())
                            ..add(const SaveFirstStepOne());
                        }
                  : null,
              child: const Text('Continuar para guardar'),
            );
          },
        ),
        const SizedBox(height: 35),
      ],
    );
  }
}
