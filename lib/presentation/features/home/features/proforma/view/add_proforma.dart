import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/bloc/proforma_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/bloc/sales_bloc.dart' as sales_bloc;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quantity_input/quantity_input.dart';

class AddFormProforma extends StatefulWidget {
  const AddFormProforma({super.key});

  @override
  State<AddFormProforma> createState() => _AddFormProformaState();
}

class _AddFormProformaState extends State<AddFormProforma> {
  // Método para mostrar el diálogo de edición de producto
  void _showEditPriceDialog(BuildContext context, sales_bloc.ProductSales product) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController observationsController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    // Inicializar controladores con valores actuales
    priceController.text = product.precio.toString();
    observationsController.text = product.observaciones ?? '';
    
    // Verificar si es un producto personalizado (ID que comienza con 2000)
    // El getter isProductPersonalizado está definido en ProductEntity y verifica si el ID comienza con 2000
    final bool isCustomProduct = product.selectedProducts?.id.toString().startsWith('2000') ?? false;
    
    // Si es un producto personalizado, inicializar el controlador de descripción
    if (isCustomProduct) {
      descriptionController.text = product.selectedProducts?.descripcion ?? '';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isCustomProduct ? 'Editar Producto Personalizado' : 'Editar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Para productos de almacén, mostrar la descripción como texto no editable
                if (!isCustomProduct) ...[  
                  Text(
                    '${product.selectedProducts?.descripcion}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                ],
                
                // Para productos personalizados, mostrar campo de edición de descripción
                if (isCustomProduct) ...[  
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 15),
                ],
                
                // Campo de precio para todos los productos
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: 'S/. ',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 15),
                
                // Campo de observaciones para todos los productos
                TextField(
                  controller: observationsController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    hintText: 'Ingrese observaciones (opcional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Validar que el precio sea un número válido
                final newPriceText = priceController.text.trim();
                final newPrice = double.tryParse(newPriceText);
                
                if (newPriceText.isEmpty) {
                  // Mostrar mensaje de error si el campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El precio no puede estar vacío'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPrice == null) {
                  // Mostrar mensaje de error si el precio no es un número válido
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El precio debe ser un número válido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPrice <= 0) {
                  // Mostrar mensaje de error si el precio es menor o igual a cero
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El precio debe ser mayor que cero'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Validar la descripción para productos personalizados
                if (isCustomProduct) {
                  final newDescription = descriptionController.text.trim();
                  if (newDescription.isEmpty) {
                    // Mostrar mensaje de error si la descripción está vacía para productos personalizados
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La descripción no puede estar vacía para productos personalizados'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }
                
                // Actualizar el precio en el bloc
                context.read<ProformaBloc>().add(
                      ProformaUpdateProductPriceInCart(
                        id: product.selectedProducts?.id ?? 0,
                        newPrice: newPrice,
                      ),
                    );
                
                // Actualizar las observaciones
                final newObservations = observationsController.text.trim();
                if (newObservations != (product.observaciones ?? '')) {
                  context.read<ProformaBloc>().add(
                        ProformaUpdateProductObservationsInCart(
                          id: product.selectedProducts?.id ?? 0,
                          observations: newObservations,
                        ),
                      );
                }
                
                // Actualizar la descripción si es un producto personalizado
                if (isCustomProduct) {
                  final newDescription = descriptionController.text.trim();
                  if (newDescription != (product.selectedProducts?.descripcion ?? '') && 
                      newDescription.isNotEmpty) {
                    try {
                      context.read<ProformaBloc>().add(
                            ProformaUpdateProductDescriptionInCart(
                              id: product.selectedProducts?.id ?? 0,
                              description: newDescription,
                            ),
                          );
                    } catch (e) {
                      print('Error al actualizar la descripción: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al actualizar la descripción del producto'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }
                }
                
                Navigator.pop(dialogContext);
                
                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto actualizado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>().state as Authenticated;
    final preferences = context.read<Preferences>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Nueva Proforma'),
      ),
      floatingActionButton: Builder(builder: (context) {
        final salesBloc = context.watch<ProformaBloc>().state;
        return salesBloc.selectedProductsSales == null ||
                salesBloc.selectedProductsSales!.isEmpty
            ? const SizedBox()
            : FloatingActionButton(
                onPressed: salesBloc.isSaveSalesLoading
                    ? null
                    : () => context.read<ProformaBloc>().add(
                          GenerateProformasProduct(
                            // TODO:: ID SUCURSSCAL
                            sucursalId: preferences.token?.sucursal?.id ?? 1,
                            userId: authBloc.user?.id ?? 1,
                          ),
                        ),
                child: const Icon(Icons.add),
              );
      }),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchCustomerProforma(),
            const SizedBox(height: 20),
            BlocConsumer<ProformaBloc, ProformaState>(
              listener: (context, state) async {
                if (state.isSaveSalesLoading) {
                  OverlayLoader.show(context);
                } else {
                  OverlayLoader.hide();
                  if (state.isSaveSalesError) {
                    ErrorSnackbar.show(
                      context,
                      'Ocurrió un problema con la proforma',
                    );
                  }

                  if (state.isSaveSalesSuccess) {
                    SuccessSnackbar.show(
                      context,
                      'Proforma generada correctamente',
                    );

                    await Future.delayed(const Duration(milliseconds: 200));
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                }
              },
              builder: (context, state) {
                switch (state.addStatus) {
                  case ProformaStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );

                  case ProformaStatus.error:
                    return Column(
                      children: [
                        const Text(
                          'No pudimos obtener datos del DNI/RUC',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Puedes ingresar los datos manualmente:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 15),
                        ManualCustomerForm(
                          documentNumber: state.lastSearchedDocument ?? '',
                          onSave: (customerData) {
                            context.read<ProformaBloc>().add(
                                  SetManualCustomerData(customerData),
                                );
                          },
                        ),
                      ],
                    );

                  case ProformaStatus.success:
                    final cliente = state.customer;
                    if (cliente == null) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Text(
                          'El Cliente no ha sido encontrado, intente de nuevo.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 70,
                                child: Text(
                                  'Cliente:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cliente.customerFullName,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 70,
                                child: Text(
                                  'Dirección:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(cliente.dni != '0'
                                    ? '${cliente.domicilio?.direccion}'
                                    : ''),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Spacer(),
                              Text(
                                'Seleccionar Productos (${state.selectedProductsSales?.length ?? 0})',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 50,
                                child: IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) {
                                        return BlocProvider.value(
                                          value: context.read<ProformaBloc>(),
                                          child: const AddProductProforma(),
                                        );
                                      },
                                    );
                                  },
                                  icon: const FaIcon(
                                    FontAwesomeIcons.circlePlus,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (state.selectedProductsSales != null) ...[
                            Text(
                              'Total a pagar:  S/. ${state.selectedProductsSales?.fold(0.0, (previousValue, element) => previousValue + (element.cantidad * element.precio)).toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.selectedProductsSales!.length,
                              itemBuilder: (context, index) {
                                final selectedProduct =
                                    state.selectedProductsSales![index];
                                final e = selectedProduct.selectedProducts;

                                final fullText =
                                    '${e?.descripcion} ${e?.marca != null && e?.marca != '' ? ' / ${e?.marca}' : ''} ${e?.modelo != null && e?.modelo != '' ? ' / ${e?.modelo}' : ''}';
                                final parsed = fullText.trimLeft();

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: e?.id.toString().startsWith('2000') == true
                                      ? const FaIcon(
                                          FontAwesomeIcons.boxOpen,
                                          size: 35,
                                        )
                                      : selectedProduct
                                                  .selectedProducts?.imagen ==
                                              null
                                          ? const SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: Placeholder(),
                                            )
                                          : CustomImageApp(
                                              urlImg: e?.imagen ?? '',
                                            ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(parsed),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            'S/ ${(selectedProduct.precio * selectedProduct.cantidad).toStringAsFixed(2)} - ',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          Text(
                                            '${selectedProduct.precio.toStringAsFixed(2)} x Und.',
                                            style:
                                                const TextStyle(fontSize: 11),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (selectedProduct
                                              .selectedProducts?.cantidad !=
                                          null)
                                        Text(
                                          '${selectedProduct.selectedProducts?.cantidad} disponible(s)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.green,
                                          ),
                                        ),
                                      if (selectedProduct.observaciones !=
                                          null) ...[
                                        Text(
                                          'Obs: ${selectedProduct.observaciones}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Botón de edición
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _showEditPriceDialog(context, selectedProduct);
                                        },
                                      ),
                                      // Control de cantidad
                                      QuantityInput(
                                        buttonColor: Colors.purple,
                                        inputWidth: 60,
                                        acceptsZero: true,
                                        maxValue: selectedProduct
                                                .selectedProducts?.cantidad ??
                                            100000,
                                        value: selectedProduct.cantidad,
                                        onChanged: (value) {
                                          if (int.parse(
                                                  value.replaceAll(',', '')) ==
                                              0) {
                                            // Eliminar
                                            context.read<ProformaBloc>().add(
                                                  DeleteProductProformasToCart(
                                                    id: selectedProduct
                                                            .selectedProducts?.id ??
                                                        0,
                                                  ),
                                                );
                                          } else {
                                            // Actualizar
                                            final cant = int.parse(
                                                value.replaceAll(',', ''));

                                            context.read<ProformaBloc>().add(
                                                  UpdateProductProformasToCart(
                                                    id: selectedProduct
                                                            .selectedProducts?.id ??
                                                        0,
                                                    quantity: cant,
                                                  ),
                                                );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    }
                  case ProformaStatus.initial:
                    return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
