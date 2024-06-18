import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/bloc/products_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductsViewLoaded extends StatefulWidget {
  const ProductsViewLoaded({
    Key? key,
    required this.state,
  }) : super(key: key);

  final ProductsLoaded state;

  @override
  State<ProductsViewLoaded> createState() => _ProductsViewLoadedState();
}

class _ProductsViewLoadedState extends State<ProductsViewLoaded> {
  final ScrollController _scrollController = ScrollController();
  CategoriesEntity? selectedCategory;
  String? selectedSearch;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    selectedCategory = widget.state.selectedCategory;
    selectedSearch = widget.state.selectedSearch;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = context.read<ProductsBloc>().state;
      if (state is ProductsLoaded && !state.hasReachedMax) {
        context
            .read<ProductsBloc>()
            .add(LoadProducts(offset: state.products.length));
      }
    }
  }

  Future<void> _onSearch(String search) async {
    setState(() => selectedSearch = search);
    _refreshProducts();
  }

  void _onCategoryChange(CategoriesEntity? category) {
    setState(() {
      selectedCategory = category;
      if (category != null) {
        _refreshProducts();
      }
    });
  }

  void _refreshProducts() {
    context.read<ProductsBloc>().add(RefreshProducts(
          search: selectedSearch,
          category: selectedCategory?.descripcion,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHeader(),
              _buildCategoryFilter(),
              if (widget.state.products.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'No se encontraron los productos',
                    ),
                  ),
                )
              else
                _buildProductList(
                    widget.state.products, widget.state.hasReachedMax),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          Positioned.fill(
            top: null,
            child: Bottom(
              categories: widget.state.categories,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchProducts(
              initialValue: selectedSearch ?? '', // Pasar valor inicial aquí
              onPressed: (search) async => await _onSearch(search),
              suffixOnPressed: () {
                setState(() {
                  selectedSearch = null; // Limpiar el valor de búsqueda
                });
                _refreshProducts(); // Actualizar la lista de productos
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
        child: AppDropdownButtonFormField<CategoriesEntity?>(
          labelText: 'Filtrar por Categoría',
          value: selectedCategory,
          onChanged: (value) => _onCategoryChange(value),
          suffixOnPressed: () {
            setState(() {
              selectedCategory =
                  null; // Limpiar la categoría seleccionada localmente
            });
            _refreshProducts(); // Cargar todos los productos nuevamente
          },
          items: widget.state.categories
              .map(
                (category) => DropdownMenuItem<CategoriesEntity?>(
                  value: category,
                  child: Text(category.descripcion),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildProductList(List<ProductEntity> products, bool hasReachedMax) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < products.length) {
            final product = products[index];
            return ListTile(
              dense: true,
              leading: const SizedBox(
                height: 50,
                width: 50,
                child: Center(child: Icon(Icons.image)),
              ),
              title: _buildProductTitle(product),
              subtitle: Text(
                '${product.marca} - ${product.modelo}',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              trailing: _buildProductActions(product, context),
            );
          } else if (!hasReachedMax && products.length > 9) {
            return const Padding(
              padding: EdgeInsets.all(10),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
        childCount: hasReachedMax ? products.length : products.length + 1,
      ),
    );
  }

  Widget _buildProductTitle(ProductEntity product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${product.descripcion} / ${product.marca} / ${product.modelo}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Préstamo - N° ${product.prestamo?.codigoFormateado ?? ''}',
          style: const TextStyle(color: Colors.blue, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProductActions(ProductEntity product, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${product.cantidad} Und.',
            style: const TextStyle(color: Colors.green)),
        const SizedBox(width: 5),
        if (product.motor != null)
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.fileInvoice,
                size: 20, color: Colors.blue),
            onPressed: () {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (_) => ContractsDetailsAlert(product: product),
              );
            },
          ),
       /*  IconButton(
          icon: const FaIcon(FontAwesomeIcons.penToSquare,
              size: 20, color: Colors.blue),
          onPressed: () async {
            final isProduct = product.motor == null;
            final result = await showDialog<StatusFormVehiculo?>(
              barrierDismissible: false,
              context: context,
              builder: (_) => EditProductDialog(
                categories: widget.state.categories,
                product: product,
                isProduct: isProduct,
              ),
            );
            if (result != null && mounted) {
              if (result.isSuccess) {
                SuccessSnackbar.show(context, result.message);
              } else {
                ErrorSnackbar.show(context, result.message);
              }
            }
          },
        ), */
      ],
    );
  }
}

class Bottom extends StatefulWidget {
  const Bottom({Key? key, required this.categories}) : super(key: key);

  final List<CategoriesEntity> categories;

  @override
  State<Bottom> createState() => _BottomState();
}

class _BottomState extends State<Bottom> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: defaultBoxShadow,
      ),
      child: Center(
        child: PrimaryButton(
          onPressed: () async {
            final result = await showDialog<StatusFormVehiculo?>(
              barrierDismissible: false,
              context: context,
              builder: (_) => AddProductDialog(
                categories: widget.categories,
              ),
            );
            if (result != null && mounted) {
              if (result.isSuccess) {
                SuccessSnackbar.show(context, result.message);
              } else {
                ErrorSnackbar.show(context, result.message);
              }
            }
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
