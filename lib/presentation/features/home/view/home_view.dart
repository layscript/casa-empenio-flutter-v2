import 'package:casa_empenio_pe/domain/domain.dart';
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
    final auth = context.read<Preferences>().token;

    return BlocProvider(
      create: (context) => HomeBloc(),
      child: Builder(builder: (context) {
        final homeState = context.watch<HomeBloc>().state;
        return WillPopScope(
          onWillPop: () async {
            if (homeState.index != 0) {
              DialogGlobalHome.show(
                context,
                homeBloc: context.read<HomeBloc>(),
              );
            }
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: AppColors.white),
              backgroundColor: AppColors.blue,
              title: const Text(
                'Casa de Empeño',
                style: TextStyle(
                  color: AppColors.white,
                ),
              ),
              centerTitle: true,
              actions: [
                if (auth?.role?.nombre == 'Administrador')
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotifyView()),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_active_sharp,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
              ],
            ),
            // color blanco del drawer
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

                  case 10:
                    return const HistorialView();

                  case 11:
                    return const OpenCajaView();

                  case 12:
                    return const PayUserView();

                  case 13:
                    return const PerdonadosView();

                  case 14:
                    return const PlantillaView();
                }
                return const SizedBox();
              },
            ),
          ),
        );
      }),
    );
  }
}
