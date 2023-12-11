import 'dart:developer';
import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
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
                labelText: 'DNI',
                keyboardType: TextInputType.number,
                maxLength: 8,
                onChanged: (e) async {
                  final newState = localState.copyWith(documentClient: e);
                  preferences.setLoansPreferences(newState);

                  if (e.length == 8) {
                    // LLamar api
                    final result = await context
                        .read<CustomerRepository>()
                        .getCustomerSunatByDni(dni: e);

                    result.fold(
                      (error) {
                        print('djdjdjdjd 5: ${error}');
                        documentClientCtrl.text = e;
                        /* documentClientCtrl.text = '';
                        namesClientCtrl.text = '';
                        lastNamesClientCtrl.text = '';
                        domicilioClientCtrl.text = '';

                        final newState = localState.copyWith(
                          documentClient: e,
                          fullNamesClient: '',
                          fullLastNamesClient: '',
                          domicilioClient: '',
                        );
                        preferences.setLoansPreferences(newState); */
                      },
                      (customer) {
                        print('djdjdjdjd 6: ${customer}');

                        final customerDni = customer.dni ?? '';
                        final customerName = customer.nombre ?? '';
                        final customerLastName =
                            '${customer.apellidoPaterno} ${customer.apellidoMaterno}';
                        final customerDomicilio =
                            customer.domicilio?.direccion ?? '';

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
                },
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
                labelText: 'Nombres',
                controller: namesClientCtrl,
                onChanged: (e) {
                  final newState = localState.copyWith(fullNamesClient: e);
                  preferences.setLoansPreferences(newState);
                },
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
                labelText: 'Celular',
                preffix: const Text('(+51)'),
                controller: phoneClientCtrl,
                keyboardType: TextInputType.phone,
                isValid: (value) {
                  setState(() {
                    isValidPhoneClient = value;
                  });
                },
                onChanged: (e) {
                  final newState = localState.copyWith(phoneClient: e);
                  preferences.setLoansPreferences(newState);
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
                labelText: 'Apellidos',
                controller: lastNamesClientCtrl,
                onChanged: (e) {
                  final newState = localState.copyWith(fullLastNamesClient: e);
                  preferences.setLoansPreferences(newState);
                },
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
          labelText: 'Correo Electrónico',
          keyboardType: TextInputType.emailAddress,
          controller: emailClientCtrl,
          inputFormatters: removeBlankSpaces,
          onChanged: (e) {
            final newState = localState.copyWith(emailClient: e);
            preferences.setLoansPreferences(newState);
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Domicilio',
          controller: domicilioClientCtrl,
          onChanged: (e) {
            final newState = localState.copyWith(domicilioClient: e);
            preferences.setLoansPreferences(newState);
          },
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPhotosClient?.removeAt(i);
                  });
                },
                child: Stack(
                  children: [
                    Image.file(
                      File(selectedPhotosClient![i].path),
                      width: 100,
                      height: 100,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.red,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedPhotosClient!.length < 2)
              Expanded(
                child: SecondaryButton(
                  onPressed: () async {
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
                        imagesClient: imagesClientState == null
                            ? [photo]
                            : [...imagesClientState, photo],
                      );
                      preferences.setLoansPreferences(newState);
                    }
                  },
                  child: Text(
                    'Subir Imagen (${2 - selectedPhotosClient!.length})',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        AppCheckbox(
          labelText: 'Agregar Aval',
          value: isAval,
          onChanged: (value) {
            setState(() {
              isAval = value ?? false;
            });
            final newState = localState.copyWith(isAval: value);
            preferences.setLoansPreferences(newState);
            /* setState(() {
              isAval = !isAval;
              isValidEmailAval = false;
              isValidNamesAval = false;
              isValidPhoneAval = false;
              isValidDocumentAval = false;
              isValidDomicilioAval = false;
              isValidLastNamesAval = false;

              documentAvalCtrl.clear();
              namesAvalCtrl.clear();
              phoneAvalCtrl.clear();
              lastNamesAvaltCtrl.clear();
              emailAvalCtrl.clear();
              domicilioAvalCtrl.clear();
              selectedPhotosAval?.clear();
              selectedPhotosAval = [];
            }); */
          },
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
                      labelText: 'DNI',
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      onChanged: (e) async {
                        final newState = localState.copyWith(documentAval: e);
                        preferences.setLoansPreferences(newState);

                        if (e.length == 8) {
                          // LLamar api
                          final result = await context
                              .read<CustomerRepository>()
                              .getCustomerSunatByDni(dni: e);

                          result.fold(
                            (error) {
                              log('djdjdjdjd 3: ${error}');
                              documentAvalCtrl.text = e;

                              /* documentAvalCtrl.text = '';
                              namesAvalCtrl.text = '';
                              lastNamesAvaltCtrl.text = '';
                              domicilioAvalCtrl.text = '';

                              final newState = localState.copyWith(
                                documentAval: e,
                                fullNamesAval: '',
                                fullLastNamesAval: '',
                                domicilioAval: '',
                              );
                              preferences.setLoansPreferences(newState); */
                            },
                            (customer) {
                              log('djdjdjdjd 4: ${customer}');

                              final customerDni = customer.dni ?? '';
                              final customerName = customer.nombre ?? '';
                              final customerLastName =
                                  '${customer.apellidoPaterno} ${customer.apellidoMaterno}';
                              final customerDomicilio =
                                  customer.domicilio?.direccion ?? '';

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
                      },
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
                      labelText: 'Nombres',
                      controller: namesAvalCtrl,
                      onChanged: (e) {
                        final newState = localState.copyWith(fullNamesAval: e);
                        preferences.setLoansPreferences(newState);
                      },
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
                      labelText: 'Celular',
                      preffix: const Text('(+51)'),
                      controller: phoneAvalCtrl,
                      keyboardType: TextInputType.phone,
                      onChanged: (e) {
                        final newState = localState.copyWith(phoneAval: e);
                        preferences.setLoansPreferences(newState);
                      },
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
                      labelText: 'Apellidos',
                      controller: lastNamesAvaltCtrl,
                      onChanged: (e) {
                        final newState =
                            localState.copyWith(fullLastNamesAval: e);
                        preferences.setLoansPreferences(newState);
                      },
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
                labelText: 'Correo Electrónico',
                keyboardType: TextInputType.emailAddress,
                inputFormatters: removeBlankSpaces,
                controller: emailAvalCtrl,
                onChanged: (e) {
                  final newState = localState.copyWith(emailAval: e);
                  preferences.setLoansPreferences(newState);
                },
              ),
              const SizedBox(height: 15),
              AppTextFormField(
                labelText: 'Domicilio',
                controller: domicilioAvalCtrl,
                onChanged: (e) {
                  final newState = localState.copyWith(domicilioAval: e);
                  preferences.setLoansPreferences(newState);
                },
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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPhotosAval?.removeAt(i);
                        });
                      },
                      child: Stack(
                        children: [
                          Image.file(
                            File(selectedPhotosAval![i].path),
                            width: 100,
                            height: 100,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.red,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedPhotosAval!.length < 2)
                    Expanded(
                      child: SecondaryButton(
                        onPressed: () async {
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
                              imagesAval: imagesAvaltState == null
                                  ? [photo]
                                  : [...imagesAvaltState, photo],
                            );
                            preferences.setLoansPreferences(newState);
                          }
                        },
                        child: Text(
                          'Subir Imagen (${2 - selectedPhotosAval!.length})',
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
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 35),
      ],
    );
  }
}
