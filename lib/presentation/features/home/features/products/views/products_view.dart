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
          const GetProducts(),
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
          listener: (context, state) {
            if (state.isProductSuccess) {
              Navigator.pop(context);
              context.read<ProductsBloc>().add(const GetProducts());
              SuccessSnackbar.show(
                context,
                'Producto/Vehiculo Agregado Correctamente',
              );
            }

            if (state.isProductFailure) {
              Navigator.pop(context);
              ErrorSnackbar.show(
                context,
                state.error ?? 'Ocurrió un problema, intentelo de nuevo',
              );
            }
          },
          builder: (context, state) {
            switch (state.productsStatus) {
              case ProductsStatus.initial || ProductsStatus.loading:
                return const ButtonStateLoading();

              case ProductsStatus.error || ProductsStatus.failed:
                return ButtonStateError(
                  onPressed: () {
                    context.read<ProductsBloc>().add(const GetProducts());
                  },
                );

              case ProductsStatus.success || ProductsStatus.loaded:
                return ProductsViewLoaded(state: state);
            }
          },
        );
      }),
    );
  }
}
