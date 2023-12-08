import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class EditFormWarranty extends StatefulWidget {
  const EditFormWarranty({super.key, required this.loansState});
  final LoansStepState loansState;

  @override
  State<EditFormWarranty> createState() => _EditFormWarrantyState();
}

class _EditFormWarrantyState extends State<EditFormWarranty> {
  String? statusWarranty;
  CategoriesEntity? categories;

  final descriptionWarrantyCtrl = TextEditingController();
  final placaWarrantyCtrl = TextEditingController();

  final marcaWarrantyCtrl = TextEditingController();
  final modeloWarrantyCtrl = TextEditingController();
  final colorWarrantyCtrl = TextEditingController();
  final serieWarrantyCtrl = TextEditingController();
  final observationWarrantyCtrl = TextEditingController();
  final priceWarrantyCtrl = TextEditingController();

  List<XFile>? selectedPhotos = [];

  bool isValidDescriptionWarranty = false;
  bool isValidMarcaWarranty = false;
  bool isValidModeloWarranty = false;
  bool isValidColorWarranty = false;
  bool isValidSerieWarranty = false;
  bool isValidObservationWarranty = false;
  bool isValidPriceWarranty = false;
  bool isValidCategories = false;

  @override
  void initState() {
    super.initState();
    callData();
  }

  void callData() {
    final loansState = widget.loansState;

    descriptionWarrantyCtrl.text = loansState.description ?? '';
    isValidDescriptionWarranty = loansState.description != null ? true : false;

    placaWarrantyCtrl.text = loansState.placa ?? '';

    marcaWarrantyCtrl.text = loansState.brand ?? '';
    isValidMarcaWarranty = loansState.brand != null ? true : false;

    modeloWarrantyCtrl.text = loansState.model ?? '';
    isValidModeloWarranty = loansState.model != null ? true : false;

    colorWarrantyCtrl.text = loansState.color ?? '';
    isValidColorWarranty = loansState.color != null ? true : false;

    serieWarrantyCtrl.text = loansState.serie ?? '';
    isValidSerieWarranty = loansState.serie != null ? true : false;

    observationWarrantyCtrl.text = loansState.warrantyObservations ?? '';
    isValidObservationWarranty =
        loansState.warrantyObservations != null ? true : false;

    priceWarrantyCtrl.text = loansState.price ?? '';
    isValidPriceWarranty = loansState.price != null ? true : false;

    getCategories(loansState.categories, loansState.listCategories);
    getPhoto(loansState.photoWarranty);
    getStatus(loansState.status);
  }

  void getCategories(
    CategoriesEntity? categoriesState,
    List<CategoriesEntity>? listCategories,
  ) {
    if (categoriesState != null && listCategories != null) {
      final response = listCategories
          .firstWhere((element) => element.id == categoriesState.id);
      setState(() {
        categories = response;
        isValidCategories = categoriesState != null ? true : false;
      });
    }
  }

  void getPhoto(List<XFile>? photo) {
    selectedPhotos = photo ?? [];
    setState(() {});
  }

  void getStatus(String? status) {
    statusWarranty = status;
    setState(() {});
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
        AppTextFormField(
          labelText: 'Descripcion',
          controller: descriptionWarrantyCtrl,
          isValid: (value) {
            setState(() {
              isValidDescriptionWarranty = value;
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
            Expanded(
              child: AppDropdownButtonFormField<CategoriesEntity?>(
                labelText: 'Categoría',
                value: categories,
                onChanged: (value) {
                  setState(() {
                    isValidCategories = true;
                    categories = value;
                  });
                },
                items: loansState.listCategories != null
                    ? loansState.listCategories!
                        .map(
                          (e) => DropdownMenuItem<CategoriesEntity?>(
                            value: e,
                            child: Text(e.descripcion),
                          ),
                        )
                        .toList()
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Placa',
                controller: placaWarrantyCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Marca',
                controller: marcaWarrantyCtrl,
                isValid: (value) {
                  setState(() {
                    isValidMarcaWarranty = value;
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
                labelText: 'Modelo',
                controller: modeloWarrantyCtrl,
                isValid: (value) {
                  setState(() {
                    isValidModeloWarranty = value;
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
              child: AppTextFormField(
                labelText: 'Color',
                controller: colorWarrantyCtrl,
                isValid: (value) {
                  setState(() {
                    isValidColorWarranty = value;
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
              child: AppDropdownButtonFormField<String?>(
                labelText: 'Estado',
                value: statusWarranty,
                onChanged: (value) {
                  setState(() {
                    statusWarranty = value;
                  });
                },
                items: ['Nuevo', 'Bueno', 'Regular']
                    .map(
                      (e) => DropdownMenuItem<String?>(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Serie',
          controller: serieWarrantyCtrl,
          isValid: (value) {
            setState(() {
              isValidSerieWarranty = value;
            });
          },
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Observaciones',
          controller: observationWarrantyCtrl,
          isValid: (value) {
            setState(() {
              isValidObservationWarranty = value;
            });
          },
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          preffix: const Text(
            'S/.',
            style: TextStyle(
              color: AppColors.black,
            ),
          ),
          labelText: 'Precio Referencial',
          keyboardType: TextInputType.number,
          controller: priceWarrantyCtrl,
          isValid: (value) {
            setState(() {
              isValidPriceWarranty = value;
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
            // Muestra las imágenes seleccionadas con opción de eliminar
            for (int i = 0; i < (selectedPhotos?.length ?? 0); i++)
              GestureDetector(
                onTap: () {
                  // Elimina la imagen del array al tocarla
                  setState(() {
                    selectedPhotos?.removeAt(i);
                  });
                },
                child: Stack(
                  children: [
                    Image.file(
                      File(selectedPhotos![i].path),
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

            // Botón para seleccionar imágenes
            if (selectedPhotos!.length < 3)
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final photo = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );

                    // Verifica si se seleccionó una imagen antes de agregarla a la lista
                    if (photo != null) {
                      setState(() {
                        selectedPhotos?.add(photo);
                      });
                    }
                  },
                  child: Text(
                    'Cargar Imagen (${3 - selectedPhotos!.length})',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        SecondaryButton(
          onPressed: () {
            context.read<LoansStepBloc>().add(
                  const ChangeStatusAddListWarranty(
                    value: false,
                  ),
                );
          },
          child: const Text('Volver'),
        ),
        const SizedBox(height: 15),
        PrimaryButton(
          onPressed: isValidDescriptionWarranty &&
                  isValidCategories &&
                  isValidMarcaWarranty &&
                  isValidModeloWarranty &&
                  isValidColorWarranty &&
                  isValidSerieWarranty &&
                  isValidObservationWarranty &&
                  isValidPriceWarranty &&
                  (selectedPhotos?.length == 3)
              ? () {
                  context.read<LoansStepBloc>().add(
                        EditListWarranty(
                          localState: localState,
                          value: WarrantyState(
                            id: widget.loansState.idWarranty,
                            description: descriptionWarrantyCtrl.text,
                            brand: marcaWarrantyCtrl.text,
                            model: modeloWarrantyCtrl.text,
                            color: colorWarrantyCtrl.text,
                            status: statusWarranty,
                            serie: serieWarrantyCtrl.text,
                            warrantyObservations: observationWarrantyCtrl.text,
                            price: priceWarrantyCtrl.text,
                            photoWarranty: selectedPhotos,
                            category: categories,
                            placa: placaWarrantyCtrl.text,
                          ),
                        ),
                      );
                }
              : null,
          child: const Text('Editar'),
        )
      ],
    );
  }
}
