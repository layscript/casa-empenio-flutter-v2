import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);
  static const route = 'home';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.blue,
            title: const Text('Casa de Empeño'),
            centerTitle: true,
          ),
          drawer: const AppDrawer(),
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              switch (state.index) {
                case 0:
                  return const MainView();

                case 1:
                  return const LoansView();

                case 2:
                  return const ReportsView();

                case 3:
                  return const SalesView();

                case 4:
                  return const ProductsView();

                case 5:
                  return const UsersView();

                case 6:
                  return const InterestsView();

                case 7:
                  return const CategoriesView();

                case 8:
                  return const CajasView();

                case 9:
                  return const ExpensesView();
              }
              return const SizedBox();
            },
          ),
        );
      }),
    );
  }
}
