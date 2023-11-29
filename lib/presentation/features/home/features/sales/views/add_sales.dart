import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/bloc/sales_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quantity_input/quantity_input.dart';

class AddFormSales extends StatelessWidget {
  const AddFormSales({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Nueva Venta'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchCustomerSales(),
            const SizedBox(height: 20),
            BlocBuilder<SalesBloc, SalesState>(
              builder: (context, state) {
                switch (state.addStatus) {
                  case SalesStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );

                  case SalesStatus.error:
                    return const Center(
                      child: Text('Ocurrió un error'),
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
                            children: [
                              const Text(
                                'Cliente:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  '${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno}'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dirección:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(cliente.dni != '0'
                                  ? '${cliente.domicilio?.direccion}'
                                  : ''),
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
                                  leading: selectedProduct
                                              .selectedProducts?.imagen ==
                                          null
                                      ? const SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Placeholder(),
                                        )
                                      : Image.network(
                                          '$endPoint/${selectedProduct.selectedProducts?.imagen}.jpg',
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
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
                                  subtitle: Text(
                                    '${selectedProduct.selectedProducts?.cantidad} disponible(s)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                    ),
                                  ),
                                  trailing: QuantityInput(
                                    buttonColor: Colors.purple,
                                    inputWidth: 60,
                                    acceptsZero: true,
                                    maxValue: selectedProduct
                                        .selectedProducts?.cantidad,
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
