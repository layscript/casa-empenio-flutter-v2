import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quantity_input/quantity_input.dart';

class AddFormProduct extends StatefulWidget {
  const AddFormProduct({
    super.key,
    required this.data,
  });
  final ProductEntity? data;

  @override
  State<AddFormProduct> createState() => _AddFormProductState();
}

class _AddFormProductState extends State<AddFormProduct> {
  List<XFile>? selectedPhotosProduct = [];
  final descripcionGarantiaController = TextEditingController();
  final marcaGarantiaController = TextEditingController();
  final modeloGarantiaController = TextEditingController();
  final observacionesGarantiaController = TextEditingController();
  final valorGarantiaController = TextEditingController();
  final placaWarrantyCtrl = TextEditingController();

  CategoriesEntity? categories;
  int cantidad = 1;

  bool isValidDescription = false;
  bool isValidCategories = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      setState(() {
        descripcionGarantiaController.text = widget.data?.descripcion ?? '';
        isValidDescription = widget.data?.descripcion != null;

        marcaGarantiaController.text = widget.data?.marca ?? '';
        placaWarrantyCtrl.text = widget.data?.placa ?? '';
        modeloGarantiaController.text = widget.data?.modelo ?? '';
        observacionesGarantiaController.text = widget.data?.observaciones ?? '';
        valorGarantiaController.text =
            widget.data?.valorizacion.toString() ?? '';
        cantidad = widget.data?.cantidad ?? 1;
      });

      getCategories(widget.data?.categoria ?? '');
      getPhotos(
        widget.data?.imagen,
        widget.data?.imagenDos,
        widget.data?.imagenTres,
      );
    }
  }

  void getPhotos(String? imagenUno, String? imagenDos, String? imagenTres) {
    List<XFile> photos = [];
    if (imagenUno != null && imagenUno != '') {
      final path = XFile(imagenUno);
      photos.add(path);
    }

    if (imagenDos != null && imagenDos != '') {
      final path = XFile(imagenDos);
      photos.add(path);
    }

    if (imagenTres != null && imagenTres != '') {
      final path = XFile(imagenTres);
      photos.add(path);
    }

    selectedPhotosProduct = photos;
    setState(() {});
  }

  void getCategories(String categoria) {
    if (categoria.isNotEmpty) {
      final productState = context.read<ProductsBloc>().state;
      final result = productState.listCategories!
          .where((element) => element.descripcion == categoria);

      setState(() {
        isValidCategories = result.isNotEmpty;
        categories = result.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<ProductsBloc>().state;

    return Column(
      children: [
        AppTextFormField(
          controller: descripcionGarantiaController,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'El campo es requerido';
            }
            return null;
          },
          isValid: (value) {
            setState(() {
              isValidDescription = value;
            });
          },
          labelText: 'Nombre',
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
                items: state.listCategories != null
                    ? state.listCategories!
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
                labelText: 'Placa (Opcional)',
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
                controller: marcaGarantiaController,
                labelText: 'Marca (Opcional)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                controller: modeloGarantiaController,
                labelText: 'Modelo (Opcional)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                controller: valorGarantiaController,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                preffix: const Text('S/. '),
                labelText: 'Costo (Opcional)',
              ),
            ),
            Expanded(
              child: Center(
                child: QuantityInput(
                  value: cantidad,
                  onChanged: (value) => setState(
                    () => cantidad = int.parse(
                      value.replaceAll(',', ''),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          controller: observacionesGarantiaController,
          labelText: 'Observaciones (Opcional)',
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            // Muestra las imágenes seleccionadas con opción de eliminar
            for (int i = 0; i < (selectedPhotosProduct?.length ?? 0); i++)
              GestureDetector(
                onTap: () {
                  // Elimina la imagen del array al tocarla
                  setState(() {
                    selectedPhotosProduct?.removeAt(i);
                  });
                },
                child: Stack(
                  children: [
                    /*  Image.file(
                      File(selectedPhotosProduct![i].path),
                      width: 100,
                      height: 100,
                    ), */
                    selectedPhotosProduct![i].path.contains('files/garantias')
                        ? Image.network(
                            '$endPoint/${selectedPhotosProduct?[i].path}',
                            width: 70,
                            height: 70,
                          )
                        : Image.file(
                            File(selectedPhotosProduct![i].path),
                            width: 70,
                            height: 70,
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
            if (selectedPhotosProduct!.length < 2)
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
                        selectedPhotosProduct?.add(photo);
                      });
                    }
                  },
                  child: Text(
                    'Cargar Imagen (${2 - selectedPhotosProduct!.length})',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: isValidDescription &&
                      isValidCategories &&
                      selectedPhotosProduct?.length == 2
                  ? () {
                      context.read<ProductsBloc>().add(
                            SaveProduct(
                              id: widget.data?.id,
                              descripcion: descripcionGarantiaController.text,
                              marca: marcaGarantiaController.text,
                              modelo: modeloGarantiaController.text,
                              valorizacion: double.parse(
                                  valorGarantiaController.text == ''
                                      ? '0'
                                      : valorGarantiaController.text),
                              observaciones:
                                  observacionesGarantiaController.text,
                              imagen: selectedPhotosProduct?[0].path ?? '',
                              imagenDos: selectedPhotosProduct?[1].path ?? '',
                              //imagenTres: selectedPhotosProduct?[2].path ?? '',
                              cantidad: cantidad,
                              categoria: categories?.descripcion ?? '',
                              placa: placaWarrantyCtrl.text,
                            ),
                          );
                    }
                  : null,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
              label: const Text(
                'Salir',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
