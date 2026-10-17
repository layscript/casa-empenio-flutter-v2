import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/auditoria_view.dart';
import 'package:casa_empenio_pe/presentation/app/utils/expedientes_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/plantilla/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/home.dart';
import 'package:casa_empenio_pe/presentation/features/home/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});
  static const route = 'main-view';

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<Preferences>();
    final preferencesState = preferences.token;

    return BlocProvider(
      lazy: false,
      create: (context) => HomeBloc(
        preferences: context.read(),
        userRepository: context.read(),
      )..add(
          const GetAllModulos(),
        ),
      child: Builder(
        builder: (context) {
          final homeState = context.watch<HomeBloc>().state;
          return WillPopScope(
            onWillPop: () async {
              if (homeState.selected?.id != 19) {
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
                  if (preferencesState?.role?.nombre == 'Administrador' &&
                      homeState.selected?.id != 15)
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
                  if (homeState.selected?.id == 15)
                    IconButton(
                      onPressed: () {
                        ShowPlantillasDialog.show(context);
                      },
                      icon: const Icon(
                        Icons.list,
                      ),
                    )
                ],
              ),
              // color blanco del drawer
              drawer: const AppDrawer(),
              body: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  // Módulos "Expedientes" y "Auditoría": se reconocen por el nombre del módulo
                  final nombreModulo =
                      (state.selected?.nombre ?? '').toLowerCase();
                  if (nombreModulo.contains('expediente')) {
                    return const ExpedientesView();
                  }
                  if (nombreModulo.contains('auditor') ||
                      nombreModulo.contains('bitacora') ||
                      nombreModulo.contains('bitácora')) {
                    return const AuditoriaView();
                  }
                  switch (state.selected?.id) {
                    case 1:
                      return const LoansView();

                    case 2:
                      return const PerdonadosView();

                    case 3:
                      return const ProformaView();

                    case 4:
                      return const ReportsView();

                    case 5:
                      return const SalesView();

                    case 6:
                      return const ProductsView();

                    case 7:
                      return const AnexosView();

                    case 8:
                      return const InterestsView();

                    case 9:
                      return const CategoriesView();

                    case 10:
                      return const ExpensesView();

                    case 11:
                      return const HistorialView();

                    case 12:
                      return const OpenCajaView();

                    case 13:
                      return const CajasView();

                    case 14:
                      return const PayUserView();

                    case 15:
                      return const PlantillaView();

                    case 16:
                      return const RolesView();

                    case 17:
                      return const UsersView();

                    case 18:
                      return const ModulosView();

                    case 19:
                      return const HomeView();
                  }

                  return const HomeView();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
