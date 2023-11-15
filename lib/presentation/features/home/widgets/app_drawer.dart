import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeBloc>().state;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AppDrawerHeader(),
            ListTile(
              tileColor: homeState.index == 0 ? Colors.black12 : null,
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                context.read<HomeBloc>().add(GoToHome());
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: homeState.index == 1 ? Colors.black12 : null,
              leading: const Icon(Icons.train),
              title: const Text('Préstamos'),
              onTap: () {
                context.read<HomeBloc>().add(GoToLoans());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.train,
              ),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.train,
              ),
              title: const Text('Ventas'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.train,
              ),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.train,
              ),
              title: const Text('Usuarios'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.train,
              ),
              title: const Text('Interes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PrimaryButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(SignOff());
                },
                child: const Text(
                  'Cerrar Sesión',
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
    final authBloc = context.watch<AuthBloc>().state;
    final isAuthenticated = authBloc is Authenticated;
    return DrawerHeader(
      margin: EdgeInsets.zero,
      decoration: const BoxDecoration(
        color: Colors.blue,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthenticated) ...[
              const FlutterLogo(
                size: 60,
              ),
              const SizedBox(height: 10),
              Text(
                '${authBloc.user.nombre} ${authBloc.user.apellido}',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${authBloc.user.role.nombre} ',
                style: const TextStyle(
                  color: Colors.white,
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'role',
                style: TextStyle(
                  color: Colors.white,
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
