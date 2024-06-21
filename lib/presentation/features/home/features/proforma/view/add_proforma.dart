import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/bloc/proforma_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/widgets/widgets.dart';
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
                    return const Center(
                      child: Text('No pudimos obtener datos del DNI'),
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
