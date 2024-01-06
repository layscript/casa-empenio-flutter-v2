import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'BIENVENIDO',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            primary: false,
            padding: const EdgeInsets.all(20),
            crossAxisSpacing: 10,
            mainAxisSpacing: 20,
            crossAxisCount: 2,
            children: <Widget>[
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToLoans(),
                    ),
                text: 'Préstamos',
                icon: FontAwesomeIcons.accusoft,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToReports(),
                    ),
                text: 'Reportes',
                icon: FontAwesomeIcons.fileArrowDown,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToSales(),
                    ),
                text: 'Ventas',
                icon: FontAwesomeIcons.message,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToProducts(),
                    ),
                text: 'Productos',
                icon: FontAwesomeIcons.cartArrowDown,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToUsers(),
                    ),
                text: 'Usuarios',
                icon: FontAwesomeIcons.user,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToInterests(),
                    ),
                text: 'Interéses',
                icon: FontAwesomeIcons.piggyBank,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToCategories(),
                    ),
                text: 'Categorías',
                icon: FontAwesomeIcons.screwdriverWrench,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToExpenses(),
                    ),
                text: 'Gastos',
                icon: FontAwesomeIcons.ccDinersClub,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToHistorial(),
                    ),
                text: 'Historial',
                icon: FontAwesomeIcons.clockRotateLeft,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToOpenCaja(),
                    ),
                text: 'Abrir Caja',
                icon: FontAwesomeIcons.boxOpen,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToCajas(),
                    ),
                text: 'Lista de Cajas',
                icon: FontAwesomeIcons.expeditedssl,
              ),
              _ItemGrid(
                onTap: () => context.read<HomeBloc>().add(
                      GoToPayUsers(),
                    ),
                text: 'Pagos a Personales',
                icon: FontAwesomeIcons.paypal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.onTap,
    required this.text,
    required this.icon,
  });

  final void Function()? onTap;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.7),
              spreadRadius: 0.2,
              blurRadius: 3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 30,
              color: const Color.fromARGB(255, 154, 218, 231),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
