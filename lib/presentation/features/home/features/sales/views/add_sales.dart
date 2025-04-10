import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/bloc/sales_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quantity_input/quantity_input.dart';

class AddFormSales extends StatefulWidget {
  const AddFormSales({super.key});

  @override
  State<AddFormSales> createState() => _AddFormSalesState();
}

class _AddFormSalesState extends State<AddFormSales> {
  // Método para mostrar el diálogo de edición de producto
  void _showEditPriceDialog(BuildContext context, ProductSales product) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController observationsController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    // Inicializar controladores con valores actuales
    priceController.text = product.precio.toString();
    observationsController.text = product.observaciones ?? '';
    
    // Verificar si es un producto personalizado
    final bool isCustomProduct = product.selectedProducts?.isProductPersonalizado ?? false;
    
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
                final newPrice = double.tryParse(priceController.text);
                if (newPrice != null && newPrice > 0) {
                  // Actualizar el precio en el bloc
                  context.read<SalesBloc>().add(
                        UpdateProductPriceInCart(
                          id: product.selectedProducts?.id ?? 0,
                          newPrice: newPrice,
                        ),
                      );
                  
                  // Actualizar las observaciones
                  final newObservations = observationsController.text.trim();
                  if (newObservations != (product.observaciones ?? '')) {
                    context.read<SalesBloc>().add(
                          UpdateProductObservationsInCart(
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
                      context.read<SalesBloc>().add(
                            UpdateProductDescriptionInCart(
                              id: product.selectedProducts?.id ?? 0,
                              description: newDescription,
                            ),
                          );
                    }
                  }
                  
                  Navigator.pop(dialogContext);
                }
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
        title: const Text('Nueva Venta'),
      ),
      floatingActionButton: Builder(builder: (context) {
        final salesBloc = context.watch<SalesBloc>().state;
        return salesBloc.selectedProductsSales == null ||
                salesBloc.selectedProductsSales!.isEmpty
            ? const SizedBox()
            : FloatingActionButton(
                onPressed: salesBloc.isSaveSalesLoading
                    ? null
                    : () => context.read<SalesBloc>().add(
                          GenerateSalesProduct(
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
            const SearchCustomerSales(),
            const SizedBox(height: 20),
            BlocConsumer<SalesBloc, SalesState>(
              listener: (context, state) async {
                if (state.isSaveSalesLoading) {
                  OverlayLoader.show(context);
                } else {
                  OverlayLoader.hide();
                  if (state.isSaveSalesError) {
                    // Mostrar el mensaje de error una sola vez
                    ErrorSnackbar.show(
                      context,
                      state.errorMessage ?? 'Ocurrió un problema con la venta',
                    );

                    // Restablecer el estado de error después de mostrar el mensaje
                    // pero mantener los datos del cliente y productos
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        context
                            .read<SalesBloc>()
                            .add(const ResetSalesErrorState());
                      }
                    });
                  }

                  if (state.isSaveSalesSuccess) {
                    SuccessSnackbar.show(
                      context,
                      'Venta generada correctamente',
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
                  case SalesStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );

                  case SalesStatus.error:
                    return Column(
                      children: [
                        const Text(
                          'No pudimos obtener datos del DNI/RUC',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
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
                            context.read<SalesBloc>().add(
                                  SetSalesManualCustomerData(customerData),
                                );
                          },
                        ),
                      ],
                    );

                  case SalesStatus.success:
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
                                          value: context.read<SalesBloc>(),
                                          child: const AddProductoSales(),
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
                                  leading: e?.isProductPersonalizado == true
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
                                            style: const TextStyle(fontSize: 11),
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
                                      // Botón de edición único para editar todos los campos
                                      Row(
                                        children: [
                                          // Mostrar observaciones si existen
                                          Expanded(
                                            child: selectedProduct.observaciones != null && selectedProduct.observaciones!.isNotEmpty
                                              ? Text(
                                                  'Obs: ${selectedProduct.observaciones}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                )
                                              : const Text(
                                                  'Sin observaciones',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                          ),
                                          // Botón de edición
                                          IconButton(
                                            onPressed: () {
                                              _showEditPriceDialog(context, selectedProduct);
                                            },
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'Editar producto',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: QuantityInput(
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
                                        context.read<SalesBloc>().add(
                                              DeleteProductSalesToCart(
                                                id: selectedProduct
                                                        .selectedProducts?.id ??
                                                    0,
                                              ),
                                            );
                                      } else {
                                        // Actualizar
                                        final cant = int.parse(
                                            value.replaceAll(',', ''));

                                        context.read<SalesBloc>().add(
                                              UpdateProductSalesToCart(
                                                id: selectedProduct
                                                        .selectedProducts?.id ??
                                                    0,
                                                quantity: cant,
                                              ),
                                            );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    }
                  case SalesStatus.initial:
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
