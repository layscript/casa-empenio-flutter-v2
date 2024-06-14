import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/bloc/sales_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quantity_input/quantity_input.dart';

class CreateProductAlmacen extends StatefulWidget {
  const CreateProductAlmacen({
    super.key,
    required this.width,
  });
  final double width;

  @override
  State<CreateProductAlmacen> createState() => _CreateProductAlmacenState();
}

class _CreateProductAlmacenState extends State<CreateProductAlmacen> {
  List<ProductEntity>? _productos;
  ProductEntity? _selection;

  final precioController = TextEditingController();
  final observacionesController = TextEditingController();

  bool isPrecioValid = false;
  int cantidad = 1;

  Future<List<ProductEntity>?> _getProducts(String text, int role) async {
    List<ProductEntity>? prodcs;
    if (role == 1) {
      final result = await context
          .read<ProductRepository>()
          .getProductsLimitFree(criterio: text);

      result.fold(
        (l) => prodcs = null,
        (r) => prodcs = r,
      );
    } else {
      final result = await context
          .read<ProductRepository>()
          .getProductsLimitSales(criterio: text);

      result.fold(
        (l) => prodcs = null,
        (r) => prodcs = r,
      );
    }

    if (prodcs != null) {
      setState(() {
        _productos = prodcs;
      });
      return prodcs;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.read<AuthBloc>().state as Authenticated;
    final role = authUser.user?.role;

    return SizedBox(
      width: widget.width * 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Autocomplete<String>(
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Selecciona un producto',
                  ),
                  onSubmitted: (value) {
                    onFieldSubmitted();
                  },
                );
              },
              optionsViewBuilder: (BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: SizedBox(
                      height: 200,
                      width: widget.width * 0.85,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return GestureDetector(
                            onTap: () {
                              onSelected(option);
                            },
                            child: ListTile(
                              title: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                } else {
                  final productos = await _getProducts(
                    textEditingValue.text,
                    role?.id ?? 0,
                  );

                  if (productos == null) return [];
                  return productos.map((e) {
                    final fullText =
                        '${e.descripcion} ${e.marca != null && e.marca != '' ? ' / ${e.marca}' : ''} ${e.modelo != null && e.modelo != '' ? ' / ${e.modelo}' : ''}';
                    final parsed = fullText.trimLeft();
                    return parsed;
                  }).toList();
                }
              },
              onSelected: (String selection) {
                if (_productos!.isNotEmpty) {
                  final result = _productos!.firstWhere((e) {
                    final fullText =
                        '${e.descripcion} ${e.marca != null && e.marca != '' ? ' / ${e.marca}' : ''} ${e.modelo != null && e.modelo != '' ? ' / ${e.modelo}' : ''}';
                    final parsed = fullText.trimLeft();
                    return parsed == selection;
                  });

                  setState(() {
                    _selection = result;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          if (_selection != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Descripción:',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          _selection?.descripcion ?? 'Sin descripcion',
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Marca:',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_selection?.marca != null && _selection?.marca != '')
                        Expanded(
                          flex: 1,
                          child: Text(
                            _selection?.marca ?? 'Sin marca',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        )
                      else
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Sin marca',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Modelo:',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_selection?.modelo != null &&
                          _selection?.modelo != '')
                        Expanded(
                          flex: 1,
                          child: Text(
                            _selection?.modelo ?? 'Sin modelo',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        )
                      else
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Sin modelo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Producto de Empeño:',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Text(
                          _selection?.prestamo != null ? 'Si' : 'No',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (_selection?.valorizacion != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Precio Sugerido:',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'S/. ${oCcy.format(double.parse(_selection?.valorizacion.toString() ?? '0.0'))}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        )
                      ],
                    ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Stock:',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          ' ${_selection?.cantidad ?? 0}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Colors.green,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
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
                Center(
                  child: SizedBox(
                    child: QuantityInput(
                      readOnly: _selection?.descripcion == '',
                      inputWidth: 50,
                      maxValue: _selection?.descripcion == ''
                          ? 1
                          : _selection?.cantidad,
                      value: cantidad,
                      onChanged: (value) {
                        setState(() {
                          cantidad = int.parse(
                            value.replaceAll(',', ''),
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            AppTextFormField(
              labelText: 'Observaciones del gasto (opcional)',
              controller: observacionesController,
            ),
            const SizedBox(height: 10),
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
                  onPressed: _selection != null && isPrecioValid
                      ? () {
                          context.read<SalesBloc>().add(
                                SaveProductSalesToCart(
                                  product: _selection,
                                  precio: double.parse(precioController.text),
                                  cantidad: cantidad,
                                  observaciones: observacionesController.text,
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
        ],
      ),
    );
  }
}
