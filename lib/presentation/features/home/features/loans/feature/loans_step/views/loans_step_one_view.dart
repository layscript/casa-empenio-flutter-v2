import 'package:image_picker/image_picker.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/utils/escaner_dni.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepOneView extends StatefulWidget {
  const LoansStepOneView({super.key});

  @override
  State<LoansStepOneView> createState() => _LoansStepOneViewState();
}

class _LoansStepOneViewState extends State<LoansStepOneView> {
  late TextEditingController _dniController;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _domicilioController;
  late LoansStepBloc loansStepBloc;
  late Preferences preferences;
  late LoansPreferencesEntity localState;
  List<XFile>? _fotosCliente;
  int _claveFotos = 0;

  @override
  void initState() {
    super.initState();
    loansStepBloc = context.read<LoansStepBloc>();
    preferences = context.read<Preferences>();
    localState = preferences.getLoansPreferences ?? LoansPreferencesEntity.init();
    _fotosCliente = localState.imagesClient;
    
    _dniController = TextEditingController(text: localState.documentClient);
    _nombresController = TextEditingController(text: localState.fullNamesClient);
    _apellidosController = TextEditingController(text: localState.fullLastNamesClient);
    _domicilioController = TextEditingController(text: localState.domicilioClient);
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _domicilioController.dispose();
    super.dispose();
  }

  /// Escanea el DNI (frente y reverso): llena DNI, nombres y apellidos, y guarda las fotos del DNI.
  Future<void> _escanearDni() async {
    final r = await abrirEscanerDni(context);
    if (r == null || !mounted) return;
    if (r.sinCamara) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la cámara. Escribe el DNI a mano.')),
      );
      return;
    }
    final d = r.datos;
    if (d.nombres.isNotEmpty) {
      _nombresController.text = d.nombres;
      loansStepBloc.add(ChangeFullNamesClient(value: d.nombres));
    }
    if (d.apellidos.isNotEmpty) {
      _apellidosController.text = d.apellidos;
      loansStepBloc.add(ChangeFullLastNamesClient(value: d.apellidos));
    }
    // Las fotos del DNI quedan abajo como miniaturas (ya guardadas, listas para el préstamo); se pueden quitar tocándolas.
    final fotos = <XFile>[
      if (r.frente != null) r.frente!,
      if (r.reverso != null) r.reverso!,
    ];
    if (fotos.isNotEmpty) {
      setState(() {
        _fotosCliente = fotos;
        _claveFotos++;
      });
      loansStepBloc.add(ChangePhotosClient(photosClient: fotos));
    }
    if (d.domicilio.isEmpty && r.reverso != null && r.textoReverso.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('No pude sacar el domicilio'),
          content: SingleChildScrollView(
            child: SelectableText('Escríbelo a mano. Esto fue lo que leí del reverso:\n\n${r.textoReverso}', style: const TextStyle(fontSize: 12)),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar'))],
        ),
      );
    }
    if (d.domicilio.isNotEmpty) {
      _domicilioController.text = d.domicilio;
      loansStepBloc.add(ChangeHomeClient(value: d.domicilio));
    }
    if (d.tieneDni) {
      _dniController.text = d.dni;
      loansStepBloc.add(ChangeDocumentClient(value: d.dni, domicilio: d.domicilio));
      revisarRiesgoCliente(context, d.dni);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el número del DNI. Escríbelo (las fotos sí se guardaron).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoansStepBloc, LoansStepState>(
      listenWhen: (previous, current) => 
        previous.fullNamesClient != current.fullNamesClient ||
        previous.fullLastNamesClient != current.fullLastNamesClient ||
        previous.homeClient != current.homeClient,
      listener: (context, state) {
        // Actualizar los controladores cuando cambie el estado
        if (state.fullNamesClient != null && state.fullNamesClient!.isNotEmpty) {
          _nombresController.text = state.fullNamesClient!;
        }
        if (state.fullLastNamesClient != null && state.fullLastNamesClient!.isNotEmpty) {
          _apellidosController.text = state.fullLastNamesClient!;
        }
        if (state.homeClient != null && state.homeClient!.isNotEmpty) {
          _domicilioController.text = state.homeClient!;
        }
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _escanearDni,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Escanear DNI (llena los datos solo)'),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                controller: _dniController,
                labelText: 'DNI (requerido)',
                keyboardType: TextInputType.number,
                maxLength: 8,
                onChanged: (e) {
                  loansStepBloc.add(
                    ChangeDocumentClient(
                      value: e,
                    ),
                  );
                  // Avisa si el cliente tiene mal historial en cualquier sucursal
                  if (e.length == 8) revisarRiesgoCliente(context, e);
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
                controller: _nombresController,
                labelText: 'Nombres (requerido)',
                onChanged: (e) => loansStepBloc.add(
                  ChangeFullNamesClient(
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
              child: AppTextFormField(
                controller: _apellidosController,
                labelText: 'Apellidos (requerido)',
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
                onChanged: (e) => loansStepBloc.add(
                  ChangeFullLastNamesClient(
                    value: e,
                  ),
                ),
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
        AppTextFormField(
          controller: _domicilioController,
          labelText: 'Domicilio (requerido)',
          onChanged: (e) => loansStepBloc.add(
            ChangeHomeClient(value: e),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        CustomImagePicker(
          key: ValueKey('fotosCliente$_claveFotos'),
          onImagesSelected: (e) => loansStepBloc.add(
            ChangePhotosClient(
              photosClient: e,
            ),
          ),
          initialSelectedPhotos: _fotosCliente,
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
    ),
    );
  }
}
