import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quantity_input/quantity_input.dart';

class AddFormVehiculo extends StatefulWidget {
  const AddFormVehiculo({super.key, required this.data});
  final ProductEntity? data;

  @override
  State<AddFormVehiculo> createState() => _AddFormVehiculoState();
}

class _AddFormVehiculoState extends State<AddFormVehiculo> {
  List<XFile>? selectedPhotosVehiculo = [];

  final descripcionController = TextEditingController();
  final marcaController = TextEditingController();
  final modeloController = TextEditingController();
  final observacionesController = TextEditingController();
  final valorController = TextEditingController();
  final carroceriaController = TextEditingController();
  final colorController = TextEditingController();
  final serieController = TextEditingController();
  final placaController = TextEditingController();
  final anioController = TextEditingController();
  final motorController = TextEditingController();
  CategoriesEntity? categories;
  int cantidad = 1;

  bool isValidDescription = false;
  bool isValidCategories = false;
  bool isValidMarca = false;
  bool isValidModelo = false;
  bool isValidCarroseria = false;
  bool isValidColor = false;
  bool isValidPlaca = false;
  bool isValidAnio = false;
  bool isValidSerie = false;
  bool isValidMotor = false;

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      setState(() {
        descripcionController.text = widget.data?.descripcion ?? '';
        isValidDescription = widget.data?.descripcion != null;

        marcaController.text = widget.data?.marca ?? '';
        isValidMarca = widget.data?.marca != null;

        modeloController.text = widget.data?.modelo ?? '';
        isValidModelo = widget.data?.modelo != null;

        observacionesController.text = widget.data?.observaciones ?? '';
        valorController.text = widget.data?.valorizacion.toString() ?? '';
        cantidad = widget.data?.cantidad ?? 1;

        carroceriaController.text = widget.data?.carroceria ?? '';
        isValidCarroseria = widget.data?.carroceria != null;

        colorController.text = widget.data?.color ?? '';
        isValidColor = widget.data?.color != null;

        serieController.text = widget.data?.serie ?? '';
        isValidSerie = widget.data?.serie != null;

        placaController.text = widget.data?.placa ?? '';
        isValidPlaca = widget.data?.placa != null;

        anioController.text = widget.data?.anio.toString() ?? '';
        isValidAnio = widget.data?.anio != null;

        motorController.text = widget.data?.motor ?? '';
        isValidMotor = widget.data?.motor != null;
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

    selectedPhotosVehiculo = photos;
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
          controller: descripcionController,
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
        AppDropdownButtonFormField<CategoriesEntity?>(
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
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                controller: marcaController,
                labelText: 'Marca',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidMarca = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                controller: modeloController,
                labelText: 'Modelo',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidModelo = value;
                  });
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
                controller: carroceriaController,
                labelText: 'Carroseria',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidCarroseria = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                controller: colorController,
                labelText: 'Color',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidColor = value;
                  });
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
                controller: placaController,
                labelText: 'Placa',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidPlaca = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                controller: anioController,
                keyboardType: TextInputType.number,
                labelText: 'Año',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidAnio = value;
                  });
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
                controller: serieController,
                labelText: 'Serie',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidSerie = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                controller: motorController,
                labelText: 'Motor',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El campo es requerido';
                  }
                  return null;
                },
                isValid: (value) {
                  setState(() {
                    isValidMotor = value;
                  });
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
                controller: valorController,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                preffix: const Text('S/. '),
                labelText: 'Costo (Opcional)',
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Center(
                child: QuantityInput(
                  readOnly: true,
                  minValue: 1,
                  maxValue: 1,
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
          //maxLines: 8,
          //minLines: 1,
          controller: observacionesController,
          labelText: 'Observaciones (Opcional)',
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            // Muestra las imágenes seleccionadas con opción de eliminar
            for (int i = 0; i < (selectedPhotosVehiculo?.length ?? 0); i++)
              GestureDetector(
                onTap: () {
                  // Elimina la imagen del array al tocarla
                  setState(() {
                    selectedPhotosVehiculo?.removeAt(i);
                  });
                },
                child: Stack(
                  children: [
                    selectedPhotosVehiculo![i].path.contains('files/garantias')
                        ? Image.network(
                            '$endPoint/${selectedPhotosVehiculo?[i].path}',
                            width: 70,
                            height: 70,
                          )
                        : Image.file(
                            File(selectedPhotosVehiculo![i].path),
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
            if (selectedPhotosVehiculo!.length < 2)
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
                        selectedPhotosVehiculo?.add(photo);
                      });
                    }
                  },
                  child: Text(
                    'Cargar Imagen (${2 - selectedPhotosVehiculo!.length})',
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
                      isValidMarca &&
                      isValidModelo &&
                      isValidCarroseria &&
                      isValidColor &&
                      isValidPlaca &&
                      isValidAnio &&
                      isValidSerie &&
                      isValidMotor &&
                      isValidCategories &&
                      selectedPhotosVehiculo?.length == 2
                  ? () {
                      context.read<ProductsBloc>().add(
                            SaveVehiculo(
                              id: widget.data?.id,
                              descripcion: descripcionController.text,
                              categoria: categories?.descripcion,
                              marca: marcaController.text,
                              modelo: modeloController.text,
                              valorizacion: double.parse(
                                  valorController.text == ''
                                      ? '0'
                                      : valorController.text),
                              observaciones: observacionesController.text,
                              imagen: selectedPhotosVehiculo?[0].path ?? '',
                              imagenDos: selectedPhotosVehiculo?[1].path ?? '',
                              cantidad: cantidad,
                              color: colorController.text,
                              serie: serieController.text,
                              placa: placaController.text,
                              anio: anioController.text,
                              motor: motorController.text,
                              carroceria: carroceriaController.text,
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
