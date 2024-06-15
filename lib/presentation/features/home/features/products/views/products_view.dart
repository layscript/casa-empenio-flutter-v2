import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/views/products_view_loaded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => ProductsBloc(
        productRepository: context.read(),
        categoriesRepository: context.read(),
      )..add(
          const LoadProducts(offset: 0),
        ),
      child: const ProductsViewBody(),
    );
  }
}

class ProductsViewBody extends StatelessWidget {
  const ProductsViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Keyboard.unfocus(context),
      child: Builder(builder: (context) {
        return BlocConsumer<ProductsBloc, ProductsState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is ProductsLoading && state.isFirstFetch) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductsLoaded) {
              return ProductsViewLoaded(state: state);
            } else if (state is ProductsError) {
              return Center(child: Text(state.error));
            } else {
              return const SizedBox();
            }
          },
        );
      }),
    );
  }
}
