import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const GetAllModulos());
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<Preferences>();
    final auth = preferences.token;

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
            Center(
              child: Text(
                '(Modulos: ${homeState.modulos?.length})',
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: homeState.modulos?.length,
              itemBuilder: (context, index) {
                int newIndex;
                if (homeState.modulos?[index].id == 19) {
                  newIndex = 0;
                } else if (index == 0 && homeState.modulos?[index].id != 19) {
                  newIndex = homeState.modulos
                          ?.indexWhere((modulo) => modulo.id == 19) ??
                      0;
                  newIndex = newIndex == -1 ? index : newIndex;
                } else {
                  newIndex = index;
                }

                final modulo = homeState.modulos?[newIndex];

                return ListTile(
                  tileColor:
                      homeState.selected == modulo ? Colors.black12 : null,
                  leading: FaIcon(
                    getIcon(modulo?.id ?? 19),
                    size: 20,
                  ),
                  title: Text(modulo?.nombre.toUpperCase() ?? 'aea'),
                  onTap: () {
                    preferences.setRefresh(true);
                    context.read<HomeBloc>().add(
                          GoToPage(modulo!),
                        );

                    Navigator.pop(context);
                  },
                );
              },
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SecondaryButton(
                onPressed: () {
                  context.read<Preferences>().setRefresh(false);
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
