import 'dart:math';

import 'package:casa_empenio_pe/domain/product/product_entity.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/bloc/proforma_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateProductPersonalizadoProforma extends StatefulWidget {
  const CreateProductPersonalizadoProforma({
    super.key,
    required this.width,
  });
  final double width;

  @override
  State<CreateProductPersonalizadoProforma> createState() =>
      _CreateProductPersonalizadoProformaState();
}

class _CreateProductPersonalizadoProformaState
    extends State<CreateProductPersonalizadoProforma> {
  final precioController = TextEditingController();
  final cantidadController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isDescriptionValid = false;
  bool isPrecioValid = false;
  bool isCantidadValid = false;

  int generateId() {
    var random = Random();
    int id =
        random.nextInt(1000000); // Genera un número aleatorio entre 0 y 999999
    return int.parse('2000$id');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width * 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextFormField(
            labelText: 'Descripción',
            keyboardType: TextInputType.text,
            controller: descriptionController,
            validator: (value) {
              if (value!.isEmpty) return 'Campo requerido';
              return null;
            },
            isValid: (value) {
              setState(() {
                isDescriptionValid = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextFormField(
                  controller: precioController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  labelText: 'Precio',
                  preffix: const Text('S/. '),
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo requerido';
                    return null;
                  },
                  isValid: (value) {
                    setState(() {
                      isPrecioValid = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: AppTextFormField(
                  controller: cantidadController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  labelText: 'Cantidad',
                  preffix: const Text('S/. '),
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo requerido';
                    return null;
                  },
                  isValid: (value) {
                    setState(() {
                      isCantidadValid = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              TextButton(
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    Colors.red,
                  ),
                  foregroundColor: MaterialStatePropertyAll(
                    Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              const Spacer(),
              TextButton(
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    Colors.blue,
                  ),
                  foregroundColor: MaterialStatePropertyAll(
                    Colors.white,
                  ),
                ),
                onPressed: isDescriptionValid &&
                        isPrecioValid &&
                        isCantidadValid
                    ? () {
                        context.read<ProformaBloc>().add(
                              SaveProductProformasToCart(
                                product: ProductEntity(
                                  id: generateId(),
                                  descripcion: descriptionController.text,
                                  categoria: null,
                                  estado: null,
                                  marca: null,
                                  modelo: null,
                                  color: null,
                                  serie: null,
                                  placa: null,
                                  carroceria: null,
                                  motor: null,
                                  anio: null,
                                  valorizacion: null,
                                  observaciones: null,
                                  cantidad: null,
                                  imagen: null,
                                  activo: null,
                                  updatedAt: null,
                                  createdAt: null,
                                  prestamo: null,
                                  imagenDos: null,
                                  imagenTres: null,
                                ),
                                precio: double.parse(precioController.text),
                                cantidad: int.parse(cantidadController.text),
                                observaciones: null,
                              ),
                            );

                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Agregar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
