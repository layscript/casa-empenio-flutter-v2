import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/bloc/products_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductsViewLoaded extends StatefulWidget {
  const ProductsViewLoaded({
    super.key,
    required this.state,
  });
  final ProductsState state;

  @override
  State<ProductsViewLoaded> createState() => _ProductsViewLoadedState();
}

class _ProductsViewLoadedState extends State<ProductsViewLoaded> {
  final _scrollController = ScrollController();
  late int _offset;
  late List<ProductEntity> _products;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _offset = 0;
    _products = widget.state.listProducts ?? [];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (_loading) return;
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _loading = true;
      });
      _offset = _offset + 10;
      await fetch(null);
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> fetch(String? search) async {
    final productRepository = context.read<ProductRepository>();
    final result = await productRepository.getProducts(
      type: 0,
      offset: search == null ? _offset : 0,
    );
    result.fold(
      (error) => null,
      (products) {
        if (search == null) {
          _products = _products + products;
        } else {
          _products = products;
        }
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsBloc = context.read<ProductsBloc>();
    return Container(
      width: double.infinity,
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
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Lista de Productos',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: SearchProducts(),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                if (widget.state.listProducts != null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20).copyWith(
                        bottom: 20,
                      ),
                      child: AppDropdownButtonFormField<CategoriesEntity?>(
                        labelText: 'Filtrar por Categoria',
                        value: widget.state.categorySelected,
                        onChanged: (value) {
                          productsBloc.add(
                            FilterProductByCategory(
                              value: value,
                            ),
                          );
                        },
                        suffixOnPressed: () {
                          productsBloc.add(
                            const GetProducts(),
                          );
                        },
                        items: widget.state.listCategories != null
                            ? widget.state.listCategories!
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
                  ),
                  SliverList.builder(
                    itemCount:
                        _loading ? _products.length + 1 : _products.length,
                    itemBuilder: (context, index) {
                      if (index < _products.length) {
                        final product = _products[index];
                        return ListTile(
                          dense: true,
                          leading: const SizedBox(
                            height: 50,
                            width: 50,
                            child: Center(
                              child: Icon(Icons.image),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.descripcion} / ${product.marca} / ${product.modelo}',
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prestamo - N° ${product.prestamo?.codigoFormateado ?? ''}',
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
                                    onPressed: () {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (_) {
                                          return ContractsDetailsAlert(
                                            product: product,
                                          );
                                        },
                                      );
                                    },
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
                                  onPressed: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (_) {
                                        final isProduct = product.motor == null;
                                        return BlocProvider.value(
                                          value: productsBloc,
                                          child: EditProductDialog(
                                            product: product,
                                            isProduct: isProduct,
                                          ),
                                        );
                                      },
                                    );
                                  },
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
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
          Positioned.fill(
            top: null,
            child: Bottom(productsBloc: productsBloc),
          ),
        ],
      ),
    );
  }
}

class Bottom extends StatelessWidget {
  const Bottom({
    super.key,
    required this.productsBloc,
  });
  final ProductsBloc productsBloc;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  value: productsBloc,
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
    );
  }
}
