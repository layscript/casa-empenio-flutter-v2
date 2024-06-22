import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddFormWarranty extends StatefulWidget {
  const AddFormWarranty({super.key});

  @override
  State<AddFormWarranty> createState() => _AddFormWarrantyState();
}

class _AddFormWarrantyState extends State<AddFormWarranty> {
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
  //XFile? photoWarranty;

  List<XFile>? selectedPhotos = [];

  bool isValidDescriptionWarranty = false;
  bool isValidMarcaWarranty = false;
  bool isValidModeloWarranty = false;
  bool isValidColorWarranty = false;
  //bool isValidSerieWarranty = false;
  bool isValidObservationWarranty = false;
  bool isValidPriceWarranty = false;
  bool isValidCategories = false;
  @override
  void initState() {
    super.initState();
    callData();
  }

  void callData() {
    final loansState = context.read<LoansStepBloc>().state;

    // Actualización de los campos según el estado actual
    descriptionWarrantyCtrl.text = loansState.description ?? '';
    isValidDescriptionWarranty = loansState.description != null;

    categories = loansState.categories;
    isValidCategories = loansState.categories != null;

    marcaWarrantyCtrl.text = loansState.brand ?? '';
    isValidMarcaWarranty = loansState.brand != null;

    modeloWarrantyCtrl.text = loansState.model ?? '';
    isValidModeloWarranty = loansState.model != null;

    colorWarrantyCtrl.text = loansState.color ?? '';
    isValidColorWarranty = loansState.color != null;

    serieWarrantyCtrl.text = loansState.serie ?? '';

    observationWarrantyCtrl.text = loansState.warrantyObservations ?? '';
    isValidObservationWarranty = loansState.warrantyObservations != null;

    priceWarrantyCtrl.text = loansState.price ?? '';
    isValidPriceWarranty = loansState.price != null;

    // Actualización de las fotos seleccionadas
    getPhoto(loansState.photoWarranty);

    // Actualización del estado
    getStatus(loansState.status);
  }

  void getPhoto(List<XFile>? photo) {
    setState(() {
      selectedPhotos = photo ?? [];
    });
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

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          _buildDescriptionField(),
          const SizedBox(height: 15),
          _buildCategoryAndPlacaRow(loansState),
          const SizedBox(height: 15),
          _buildBrandAndModelRow(),
          const SizedBox(height: 15),
          _buildColorAndStatusRow(),
          const SizedBox(height: 15),
          _buildOptionalFields(),
          const SizedBox(height: 15),
          _buildPhotoSelectionRow(),
          const SizedBox(height: 15),
          _buildButtons(loansState, localState),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return AppTextFormField(
      labelText: 'Descripción (requerido)',
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
    );
  }

  Widget _buildCategoryAndPlacaRow(LoansStepState loansState) {
    return Row(
      children: [
        Expanded(
          child: AppDropdownButtonFormField<CategoriesEntity?>(
            labelText: 'Categoría (requerido)',
            value: categories,
            onChanged: (value) {
              setState(() {
                isValidCategories = true;
                categories = value;
              });
            },
            items: loansState.listCategories
                ?.map((e) => DropdownMenuItem<CategoriesEntity?>(
                      value: e,
                      child: Text(e.descripcion),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppTextFormField(
            labelText: 'Placa (opcional)',
            controller: placaWarrantyCtrl,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandAndModelRow() {
    return Row(
      children: [
        Expanded(
          child: AppTextFormField(
            labelText: 'Marca (requerido)',
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
            labelText: 'Modelo (requerido)',
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
    );
  }

  Widget _buildColorAndStatusRow() {
    return Row(
      children: [
        Expanded(
          child: AppTextFormField(
            labelText: 'Color (requerido)',
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
            labelText: 'Estado (requerido)',
            value: statusWarranty,
            onChanged: (value) {
              setState(() {
                statusWarranty = value;
              });
            },
            items: ['nuevo', 'bueno', 'regular']
                .map((e) => DropdownMenuItem<String?>(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextFormField(
          labelText: 'Serie (opcional)',
          controller: serieWarrantyCtrl,
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Observaciones (requerido)',
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
          labelText: 'Precio Referencial (requerido)',
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
      ],
    );
  }

  Widget _buildPhotoSelectionRow() {
    return Row(
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

        // Botón para seleccionar imágenes desde la cámara
        if (selectedPhotos!.length < 2)
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
                'Tomar Foto (${2 - selectedPhotos!.length})',
              ),
            ),
          ),
        const SizedBox(width: 10),
        // Botón para seleccionar imagen desde la galería
        if (selectedPhotos!.length < 3)
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final photo = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );

                // Verifica si se seleccionó una imagen antes de agregarla a la lista
                if (photo != null) {
                  setState(() {
                    selectedPhotos?.add(photo);
                  });
                }
              },
              child: const Text(
                'Subir Imagen (1)',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButtons(
    LoansStepState loansState,
    LoansPreferencesEntity localState,
  ) {
    return Column(
      children: [
        SecondaryButton(
          onPressed: () {
            // Lógica para volver atrás
            if (loansState.listWarranty == null ||
                loansState.listWarranty!.isEmpty) {
              context.read<LoansStepBloc>().add(
                    SaveThirdStepOne(
                      index: 1,
                      value: WarrantyState(
                        id: generateIDFromDateTime(),
                        category: categories,
                        placa: placaWarrantyCtrl.text,
                        description: descriptionWarrantyCtrl.text,
                        brand: marcaWarrantyCtrl.text,
                        model: modeloWarrantyCtrl.text,
                        color: colorWarrantyCtrl.text,
                        status: statusWarranty,
                        serie: serieWarrantyCtrl.text,
                        warrantyObservations: observationWarrantyCtrl.text,
                        price: priceWarrantyCtrl.text,
                        photoWarranty: selectedPhotos,
                      ),
                    ),
                  );
            } else {
              context.read<LoansStepBloc>().add(
                    const ChangeStatusAddListWarranty(
                      value: false,
                    ),
                  );
            }
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
                  isValidObservationWarranty &&
                  isValidPriceWarranty
              ? () {
                  context.read<LoansStepBloc>().add(
                        AddListWarranty(
                          localState: localState,
                          value: WarrantyState(
                            id: generateIDFromDateTime(),
                            category: categories,
                            placa: placaWarrantyCtrl.text,
                            description: descriptionWarrantyCtrl.text,
                            brand: marcaWarrantyCtrl.text,
                            model: modeloWarrantyCtrl.text,
                            color: colorWarrantyCtrl.text,
                            status: statusWarranty,
                            serie: serieWarrantyCtrl.text,
                            warrantyObservations:
                                observationWarrantyCtrl.text,
                            price: priceWarrantyCtrl.text,
                            photoWarranty: selectedPhotos,
                          ),
                        ),
                      );
                }
              : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
