import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Preferences>().token;
    final homeState = context.watch<HomeBloc>().state;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AppDrawerHeader(),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '(${auth?.sucursal?.nombre ?? 'Sucursal principal'})',
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: homeState.index == 0 ? Colors.black12 : null,
              leading: const FaIcon(
                FontAwesomeIcons.house,
                size: 20,
              ),
              title: const Text('Inicio'),
              onTap: () {
                context.read<HomeBloc>().add(GoToHome());
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: homeState.index == 1 ? Colors.black12 : null,
              leading: const FaIcon(
                FontAwesomeIcons.accusoft,
                size: 20,
              ),
              title: const Text('Préstamos'),
              onTap: () {
                context.read<HomeBloc>().add(GoToLoans());
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: homeState.index == 13 ? Colors.black12 : null,
              leading: const FaIcon(
                FontAwesomeIcons.doorClosed,
                size: 20,
              ),
              title: const Text('Perdonados'),
              onTap: () {
                context.read<HomeBloc>().add(GoToPerdonados());
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: homeState.index == 2 ? Colors.black12 : null,
              leading: const FaIcon(
                FontAwesomeIcons.fileArrowDown,
                size: 20,
              ),
              title: const Text('Reportes'),
              onTap: () {
                context.read<HomeBloc>().add(GoToReports());
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: homeState.index == 3 ? Colors.black12 : null,
              leading: const FaIcon(
                FontAwesomeIcons.message,
                size: 20,
              ),
              title: const Text('Ventas'),
              onTap: () {
                context.read<HomeBloc>().add(GoToSales());
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: homeState.index == 4 ? Colors.black12 : null,
              leading: const FaIcon(
                FontAwesomeIcons.cartArrowDown,
                size: 20,
              ),
              title: const Text('Productos'),
              onTap: () {
                context.read<HomeBloc>().add(GoToProducts());
                Navigator.pop(context);
              },
            ),
            if (auth?.role?.nombre == 'Administrador')
              ListTile(
                tileColor: homeState.index == 5 ? Colors.black12 : null,
                leading: const FaIcon(
                  FontAwesomeIcons.user,
                  size: 20,
                ),
                title: const Text('Usuarios'),
                onTap: () {
                  context.read<HomeBloc>().add(GoToUsers());
                  Navigator.pop(context);
                },
              ),
            if (auth?.role?.nombre == 'Administrador')
              ListTile(
                tileColor: homeState.index == 6 ? Colors.black12 : null,
                leading: const FaIcon(
                  FontAwesomeIcons.piggyBank,
                  size: 20,
                ),
                title: const Text('Interes'),
                onTap: () {
                  context.read<HomeBloc>().add(GoToInterests());
                  Navigator.pop(context);
                },
              ),
            ListTile(
              tileColor: homeState.index == 7 ? Colors.black12 : null,
              leading: const FaIcon(
                FontAwesomeIcons.screwdriverWrench,
                size: 20,
              ),
              title: const Text('Categorías'),
              onTap: () {
                context.read<HomeBloc>().add(GoToCategories());
                Navigator.pop(context);
              },
            ),
            if (auth?.role?.nombre == 'Administrador')
              ListTile(
                tileColor: homeState.index == 11 ? Colors.black12 : null,
                leading: const FaIcon(
                  FontAwesomeIcons.boxOpen,
                  size: 20,
                ),
                title: const Text('Caja'),
                onTap: () {
                  context.read<HomeBloc>().add(GoToOpenCaja());
                  Navigator.pop(context);
                },
              ),
            if (auth?.role?.nombre == 'Administrador')
              ListTile(
                tileColor: homeState.index == 8 ? Colors.black12 : null,
                leading: const FaIcon(
                  FontAwesomeIcons.expeditedssl,
                  size: 20,
                ),
                title: const Text('Lista de Cajas'),
                onTap: () {
                  context.read<HomeBloc>().add(GoToCajas());
                  Navigator.pop(context);
                },
              ),
            if (auth?.role?.nombre == 'Administrador')
              ListTile(
                tileColor: homeState.index == 9 ? Colors.black12 : null,
                leading: const FaIcon(
                  FontAwesomeIcons.ccDinersClub,
                  size: 20,
                ),
                title: const Text('Gastos'),
                onTap: () {
                  context.read<HomeBloc>().add(GoToExpenses());
                  Navigator.pop(context);
                },
              ),
            if (auth?.role?.nombre == 'Administrador')
              ListTile(
                tileColor: homeState.index == 10 ? Colors.black12 : null,
                leading: const FaIcon(
                  FontAwesomeIcons.clockRotateLeft,
                  size: 20,
                ),
                title: const Text('Historial'),
                onTap: () {
                  context.read<HomeBloc>().add(GoToHistorial());
                  Navigator.pop(context);
                },
              ),
            if (auth?.role?.nombre == 'Administrador')
              ListTile(
                tileColor: homeState.index == 12 ? Colors.black12 : null,
                leading: const FaIcon(
                  FontAwesomeIcons.paypal,
                  size: 20,
                ),
                title: const Text('Pagos a Personales'),
                onTap: () {
                  context.read<HomeBloc>().add(GoToPayUsers());
                  Navigator.pop(context);
                },
              ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SecondaryButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(SignOff());
                },
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.circleArrowLeft),
                    SizedBox(width: 10),
                    Text(
                      'Cerrar Sesión',
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final authBloc = context.watch<AuthBloc>().state;
    //final isAuthenticated = authBloc is Authenticated;
    final auth = context.read<Preferences>().token;

    return DrawerHeader(
      margin: EdgeInsets.zero,
      /* decoration: const BoxDecoration(
        color: Color.fromARGB(255, 7, 91, 65),
      ), */
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth != null) ...[
              if (auth.avatar == null)
                const FlutterLogo(
                  size: 60,
                )
              else
                Image.network(
                  auth.avatar!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 10),
              Text(
                '${auth.nombre} ${auth.apellido}',
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${auth.role?.nombre} ',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              const FlutterLogo(
                size: 60,
              ),
              const SizedBox(height: 10),
              const Text(
                'username',
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'role',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
