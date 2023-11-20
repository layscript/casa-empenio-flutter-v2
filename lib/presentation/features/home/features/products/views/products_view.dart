import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => ProductsBloc(productRepository: context.read())
        ..add(
          GetProducts(),
        ),
      child: Builder(builder: (context) {
        return BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            switch (state) {
              case ProductsLoading() || ProductsInitial():
                return const Center(
                  child: CupertinoActivityIndicator(),
                );

              case ProductsError():
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<ProductsBloc>().add(GetProducts()),
                        child: const Text(
                          'Cargar de nuevo',
                        ),
                      )
                    ],
                  ),
                );

              case ProductsLoaded():
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: MediaQuery.of(context).size.height * 0.9,
                        padding: const EdgeInsets.only(
                          bottom: 120,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Lista de Productos',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: AppTextFormField(
                                  labelText: 'Buscar ...',
                                ),
                              ),
                              const SizedBox(height: 20),
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(
                                  height: 10,
                                ),
                                shrinkWrap: true,
                                itemCount: state.listProducts.length,
                                itemBuilder: (context, index) {
                                  final product = state.listProducts[index];
                                  return ListTile(
                                    dense: true,
                                    leading: product.imagen == null
                                        ? const SizedBox(
                                            height: 50,
                                            width: 50,
                                            child: Center(
                                              child: Icon(Icons.image),
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () {},
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.red,
                                            ),
                                            /* child: CachedNetworkImage(
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.scaleDown,
                                              imageUrl: product.imagen!
                                                      .contains('.jpg')
                                                  ? '$endPoint/${product.imagen}'
                                                  : '$endPoint/${product.imagen}.jpg',
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child: SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) =>
                                                  const Icon(Icons.error),
                                            ), */
                                          ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${product.descripcion} / ${product.marca} / ${product.modelo}',
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Prestamo - N° ${product.prestamo?.codigoFormateado}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                          ),
                                        )
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${product.marca} - ${product.modelo}',
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${product.cantidad} Und.',
                                          style: const TextStyle(
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        if (product.motor != null)
                                          SizedBox(
                                            height: 40,
                                            child: IconButton(
                                              onPressed: () {},
                                              icon: const FaIcon(
                                                FontAwesomeIcons.fileInvoice,
                                                size: 20,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        SizedBox(
                                          width: 40,
                                          child: IconButton(
                                            onPressed: () {},
                                            icon: const FaIcon(
                                              FontAwesomeIcons.penToSquare,
                                              size: 20,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: null,
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: defaultBoxShadow,
                          ),
                          child: Center(
                            child: PrimaryButton(
                              onPressed: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (_) {
                                    return BlocProvider.value(
                                      value: context.read<ProductsBloc>(),
                                      child: const AddProductDialog(),
                                    );
                                  },
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.circlePlus),
                                  SizedBox(width: 10),
                                  Text('Agregar Producto'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              default:
            }

            return const SizedBox();
          },
        );
      }),
    );
  }
}
