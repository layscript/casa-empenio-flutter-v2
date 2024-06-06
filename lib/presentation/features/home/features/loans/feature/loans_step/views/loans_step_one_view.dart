import 'dart:io';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/feature/loans_step/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class LoansStepOneView extends StatefulWidget {
  const LoansStepOneView({super.key});

  @override
  State<LoansStepOneView> createState() => _LoansStepOneViewState();
}

class _LoansStepOneViewState extends State<LoansStepOneView> {
  /// Controladores del Cliente
  List<XFile>? selectedPhotosClient = [];
  final documentClientCtrl = TextEditingController();
  final namesClientCtrl = TextEditingController();
  final lastNamesClientCtrl = TextEditingController();
  final phoneClientCtrl = TextEditingController();
  final emailClientCtrl = TextEditingController();
  final domicilioClientCtrl = TextEditingController();

  /// Controladores del Aval
  List<XFile>? selectedPhotosAval = [];
  final documentAvalCtrl = TextEditingController();
  final namesAvalCtrl = TextEditingController();
  final lastNamesAvaltCtrl = TextEditingController();
  final phoneAvalCtrl = TextEditingController();
  final emailAvalCtrl = TextEditingController();
  final domicilioAvalCtrl = TextEditingController();

  // Flag del Aval
  bool isAval = false;

  // Validaciones de los controladores
  bool isValidDocumentClient = false;
  bool isValidNamesClient = false;
  bool isValidLastNamesClient = false;
  bool isValidPhoneClient = false;
  bool isValidDomicilioClient = false;

  bool isValidDocumentAval = false;
  bool isValidNamesAval = false;
  bool isValidLastNamesAval = false;
  bool isValidPhoneAval = false;
  bool isValidDomicilioAval = false;

  @override
  void initState() {
    super.initState();
    // Obtener data almacenada
    getLocalData();
  }

  void getLocalData() {
    // Estado local y bloc
    final state = context.read<LoansStepBloc>().state;
    final preferences = context.read<Preferences>();
    final localState = preferences.getLoansPreferences;

    // Set a los controladores
    documentClientCtrl.text =
        state.documentClient ?? localState?.documentClient ?? '';

    namesClientCtrl.text =
        state.fullNamesClient ?? localState?.fullNamesClient ?? '';

    lastNamesClientCtrl.text =
        state.fullLastNamesClient ?? localState?.fullLastNamesClient ?? '';

    phoneClientCtrl.text = state.phoneClient ?? localState?.phoneClient ?? '';

    emailClientCtrl.text = state.emailClient ?? localState?.emailClient ?? '';

    domicilioClientCtrl.text =
        state.homeClient ?? localState?.domicilioClient ?? '';

    documentAvalCtrl.text =
        state.documentAval ?? localState?.documentAval ?? '';

    namesAvalCtrl.text = state.fullNamesAval ?? localState?.fullNamesAval ?? '';

    lastNamesAvaltCtrl.text =
        state.fullLastNamesAval ?? localState?.fullLastNamesAval ?? '';

    phoneAvalCtrl.text = state.phoneAval ?? localState?.phoneAval ?? '';

    emailAvalCtrl.text = state.emailAval ?? localState?.emailAval ?? '';

    domicilioAvalCtrl.text = state.homeAval ?? localState?.domicilioAval ?? '';

    // Set a las validaciones
    isValidDocumentClient = state.documentClient != null
        ? true
        : localState?.documentClient != null
            ? true
            : false;

    isValidNamesClient = state.fullNamesClient != null
        ? true
        : localState?.fullNamesClient != null
            ? true
            : false;

    isValidLastNamesClient = state.fullLastNamesClient != null
        ? true
        : localState?.fullLastNamesClient != null
            ? true
            : false;

    isValidPhoneClient = state.phoneClient != null
        ? true
        : localState?.phoneClient != null
            ? true
            : false;

    isValidDomicilioClient = state.homeClient != null
        ? true
        : localState?.domicilioClient != null
            ? true
            : false;

    isValidDocumentAval = state.documentAval != null
        ? true
        : localState?.documentAval != null
            ? true
            : false;

    isValidNamesAval = state.fullNamesAval != null
        ? true
        : localState?.fullNamesAval != null
            ? true
            : false;

    isValidLastNamesAval = state.fullLastNamesAval != null
        ? true
        : localState?.fullLastNamesAval != null
            ? true
            : false;

    isValidPhoneAval = state.phoneAval != null
        ? true
        : localState?.phoneAval != null
            ? true
            : false;

    isValidDomicilioAval = state.homeAval != null
        ? true
        : localState?.domicilioAval != null
            ? true
            : false;

    // Set funciones
    getPhotosClient(state.photosClient ?? localState?.imagesClient);
    getPhotosAval(state.photosAval ?? localState?.imagesAval);
    getIsAval(localState?.isAval ?? state.isAval);
  }

  void getIsAval(bool? newAval) {
    isAval = newAval ?? false;
    setState(() {});
  }

  void getPhotosClient(List<XFile>? photo) {
    setState(() {
      selectedPhotosClient = photo ?? [];
    });
  }

  void getPhotosAval(List<XFile>? photo) {
    setState(() {
      selectedPhotosAval = photo ?? [];
    });
  }

  // Events Client
  void onChangeDocumentClient({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) async {
    final newState = localState.copyWith(documentClient: value);
    preferences.setLoansPreferences(newState);
    if (value.length == 8) {
      final result = await context
          .read<CustomerRepository>()
          .getCustomerSunatByDni(dni: value);

      result.fold(
        (error) {
          documentClientCtrl.text = value;
        },
        (customer) {
          final customerDni = customer.dni ?? '';
          final customerName = customer.nombre ?? '';
          final customerLastName =
              '${customer.apellidoPaterno} ${customer.apellidoMaterno}';
          final customerDomicilio = customer.domicilio?.direccion ?? '';

          documentClientCtrl.text = customerDni;
          namesClientCtrl.text = customerName;
          lastNamesClientCtrl.text = customerLastName;
          domicilioClientCtrl.text = customerDomicilio;

          final newState = localState.copyWith(
            documentClient: customerDni,
            fullNamesClient: customerName,
            fullLastNamesClient: customerLastName,
            domicilioClient: customerDomicilio,
          );
          preferences.setLoansPreferences(newState);
        },
      );
    }
  }

  void onChangeNamesClient({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) async {
    final newState = localState.copyWith(fullNamesClient: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangePhoneClient({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) async {
    final newState = localState.copyWith(phoneClient: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangeLastNamesClient({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(fullLastNamesClient: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangeEmailClient({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(emailClient: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangeDomicilioClient({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(domicilioClient: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangePhotosClient({
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        selectedPhotosClient?.add(photo);
      });

      final imagesClientState = localState.imagesClient;
      final newState = localState.copyWith(
        imagesClient:
            imagesClientState == null ? [photo] : [...imagesClientState, photo],
      );
      preferences.setLoansPreferences(newState);
    }
  }

  // Events Aval
  void onChangeAval({
    required bool? value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    setState(() {
      isAval = value ?? false;
    });
    final newState = localState.copyWith(isAval: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangeDocumentAval({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) async {
    final newState = localState.copyWith(documentAval: value);
    preferences.setLoansPreferences(newState);

    if (value.length == 8) {
      // LLamar api
      final result = await context
          .read<CustomerRepository>()
          .getCustomerSunatByDni(dni: value);

      result.fold(
        (error) {
          documentAvalCtrl.text = value;
        },
        (customer) {
          final customerDni = customer.dni ?? '';
          final customerName = customer.nombre ?? '';
          final customerLastName =
              '${customer.apellidoPaterno} ${customer.apellidoMaterno}';
          final customerDomicilio = customer.domicilio?.direccion ?? '';

          documentAvalCtrl.text = customerDni;
          namesAvalCtrl.text = customerName;
          lastNamesAvaltCtrl.text = customerLastName;
          domicilioAvalCtrl.text = customerDomicilio;

          final newState = localState.copyWith(
            documentAval: customerDni,
            fullNamesAval: customerName,
            fullLastNamesAval: customerLastName,
            domicilioAval: customerDomicilio,
          );
          preferences.setLoansPreferences(newState);
        },
      );
    }
  }

  void onChangeNamesAval({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(fullNamesAval: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangePhoneAval({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(phoneAval: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangeLastNamesAval({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(fullLastNamesAval: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangeEmailAval({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(emailAval: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangeDomicilioAval({
    required String value,
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) {
    final newState = localState.copyWith(domicilioAval: value);
    preferences.setLoansPreferences(newState);
  }

  void onChangePhotosAval({
    required LoansPreferencesEntity localState,
    required Preferences preferences,
  }) async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        selectedPhotosAval?.add(photo);
      });

      final imagesAvaltState = localState.imagesAval;
      final newState = localState.copyWith(
        imagesAval:
            imagesAvaltState == null ? [photo] : [...imagesAvaltState, photo],
      );
      preferences.setLoansPreferences(newState);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                controller: documentClientCtrl,
                labelText: 'DNI (requerido)',
                keyboardType: TextInputType.number,
                maxLength: 8,
                onChanged: (e) => onChangeDocumentClient(
                  value: e,
                  localState: localState,
                  preferences: preferences,
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  if (value.length < 8) return 'Ingresar 8 Dígitos';
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidDocumentClient = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Nombres (requerido)',
                controller: namesClientCtrl,
                onChanged: (e) => onChangeNamesClient(
                  value: e,
                  localState: localState,
                  preferences: preferences,
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidNamesClient = value;
                  });
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
                controller: phoneClientCtrl,
                keyboardType: TextInputType.phone,
                isValid: (value) {
                  setState(() {
                    isValidPhoneClient = value;
                  });
                },
                onChanged: (e) => onChangePhoneClient(
                  value: e,
                  localState: localState,
                  preferences: preferences,
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
                labelText: 'Apellidos (requerido)',
                controller: lastNamesClientCtrl,
                onChanged: (e) => onChangeLastNamesClient(
                  value: e,
                  localState: localState,
                  preferences: preferences,
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidLastNamesClient = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Correo Electrónico (opcional)',
          keyboardType: TextInputType.emailAddress,
          controller: emailClientCtrl,
          inputFormatters: removeBlankSpaces,
          onChanged: (e) => onChangeEmailClient(
            value: e,
            localState: localState,
            preferences: preferences,
          ),
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Domicilio (requerido)',
          controller: domicilioClientCtrl,
          onChanged: (e) => onChangeDomicilioClient(
            value: e,
            localState: localState,
            preferences: preferences,
          ),
          isValid: (value) {
            setState(() {
              isValidDomicilioClient = value;
            });
          },
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            for (int i = 0; i < (selectedPhotosClient?.length ?? 0); i++)
              CustomImageClient(
                onTap: () {
                  setState(() {
                    selectedPhotosClient?.removeAt(i);
                  });
                },
                path: selectedPhotosClient![i].path,
              ),
            if (selectedPhotosClient!.length < 2)
              Expanded(
                child: SecondaryButton(
                  onPressed: () => onChangePhotosClient(
                    localState: localState,
                    preferences: preferences,
                  ),
                  child: Text(
                    'Subir Imagen (${2 - selectedPhotosClient!.length}) - opcional',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        // Form AVAL
        AppCheckbox(
          labelText: 'Agregar Aval',
          value: isAval,
          onChanged: (value) => onChangeAval(
            value: value,
            localState: localState,
            preferences: preferences,
          ),
        ),
        if (isAval) ...[
          Column(
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
                      controller: documentAvalCtrl,
                      labelText: 'DNI (requerido)',
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      onChanged: (e) => onChangeDocumentAval(
                        value: e,
                        localState: localState,
                        preferences: preferences,
                      ),
                      isValid: (value) {
                        setState(() {
                          isValidDocumentAval = value;
                        });
                      },
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
                      labelText: 'Nombres (requerido)',
                      controller: namesAvalCtrl,
                      onChanged: (e) => onChangeNamesAval(
                        value: e,
                        localState: localState,
                        preferences: preferences,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return 'Campo Requerido';
                        return null;
                      },
                      isValid: (value) {
                        setState(() {
                          isValidNamesAval = value;
                        });
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
                      controller: phoneAvalCtrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (e) => onChangePhoneAval(
                        value: e,
                        localState: localState,
                        preferences: preferences,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return 'Campo Requerido';
                        return null;
                      },
                      isValid: (value) {
                        setState(() {
                          isValidPhoneAval = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextFormField(
                      labelText: 'Apellidos (requerido)',
                      controller: lastNamesAvaltCtrl,
                      onChanged: (e) => onChangeLastNamesAval(
                        value: e,
                        localState: localState,
                        preferences: preferences,
                      ),
                      isValid: (value) {
                        setState(() {
                          isValidLastNamesAval = value;
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
              AppTextFormField(
                labelText: 'Correo Electrónico (opcional)',
                keyboardType: TextInputType.emailAddress,
                inputFormatters: removeBlankSpaces,
                controller: emailAvalCtrl,
                onChanged: (e) => onChangeEmailAval(
                  value: e,
                  localState: localState,
                  preferences: preferences,
                ),
              ),
              const SizedBox(height: 15),
              AppTextFormField(
                labelText: 'Domicilio (requerido)',
                controller: domicilioAvalCtrl,
                onChanged: (e) => onChangeDomicilioAval(
                  value: e,
                  localState: localState,
                  preferences: preferences,
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidDomicilioAval = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  for (int i = 0; i < (selectedPhotosAval?.length ?? 0); i++)
                    CustomImageClient(
                      onTap: () {
                        setState(() {
                          selectedPhotosAval?.removeAt(i);
                        });
                      },
                      path: selectedPhotosAval![i].path,
                    ),
                  if (selectedPhotosAval!.length < 2)
                    Expanded(
                      child: SecondaryButton(
                        onPressed: () => onChangePhotosAval(
                          localState: localState,
                          preferences: preferences,
                        ),
                        child: Text(
                          'Subir Imagen (${2 - selectedPhotosAval!.length}) - opcional',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ],
        const SizedBox(height: 15),
        PrimaryButton(
          onPressed: isValidDocumentClient &&
                  isValidNamesClient &&
                  isValidLastNamesClient &&
                  isValidPhoneClient &&
                  isValidDomicilioClient /* &&
                  selectedPhotosClient?.length == 2 */
              ? isAval
                  ? isValidDocumentAval &&
                          isValidNamesAval &&
                          isValidLastNamesAval &&
                          isValidPhoneAval &&
                          isValidDomicilioAval /*  &&
                          selectedPhotosAval?.length == 2 */
                      ? () {
                          context.read<LoansStepBloc>().add(
                                SaveFirstStepOne(
                                  documentClient: documentClientCtrl.text,
                                  namesClient: namesClientCtrl.text,
                                  phoneClient: phoneClientCtrl.text,
                                  lastNamesClient: lastNamesClientCtrl.text,
                                  emailClient: emailClientCtrl.text,
                                  domicilioClient: domicilioClientCtrl.text,
                                  isAval: isAval,
                                  documentAval: documentAvalCtrl.text,
                                  namesAval: namesAvalCtrl.text,
                                  phoneAval: phoneAvalCtrl.text,
                                  lastNamesAval: lastNamesAvaltCtrl.text,
                                  emailAval: emailAvalCtrl.text,
                                  domicilioAval: domicilioAvalCtrl.text,
                                  photosClient: selectedPhotosClient,
                                  photosAval: selectedPhotosAval,
                                ),
                              );
                        }
                      : null
                  : () {
                      context.read<LoansStepBloc>().add(
                            SaveFirstStepOne(
                              documentClient: documentClientCtrl.text,
                              namesClient: namesClientCtrl.text,
                              phoneClient: phoneClientCtrl.text,
                              lastNamesClient: lastNamesClientCtrl.text,
                              emailClient: emailClientCtrl.text,
                              domicilioClient: domicilioClientCtrl.text,
                              isAval: isAval,
                              documentAval: documentAvalCtrl.text,
                              namesAval: namesAvalCtrl.text,
                              phoneAval: phoneAvalCtrl.text,
                              lastNamesAval: lastNamesAvaltCtrl.text,
                              emailAval: emailAvalCtrl.text,
                              domicilioAval: domicilioAvalCtrl.text,
                              photosClient: selectedPhotosClient,
                              photosAval: selectedPhotosAval,
                            ),
                          );
                    }
              : null,
          child: const Text('Continuar para guardar'),
        ),
        const SizedBox(height: 35),
      ],
    );
  }
}
