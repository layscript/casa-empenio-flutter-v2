import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/actualizaciones.dart';
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
                final modulo = homeState.modulos?[index];
                final activo = homeState.selected == modulo;
                return ListTile(
                  tileColor: activo ? AppColors.blue.withOpacity(0.10) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  leading: FaIcon(
                    getIcon(modulo?.id ?? 19),
                    size: 20,
                    color: activo ? AppColors.blue : AppColors.secondaryText,
                  ),
                  title: Text(
                    modulo?.nombre.toUpperCase() ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                      color: activo ? AppColors.blue : AppColors.primaryText,
                    ),
                  ),
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
            if (auth?.isAdmin == true)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppColors.blue),
                title: const Text('Trabajar en otra sucursal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('Ahora: ${auth?.sucursal?.nombre ?? '-'}', style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  final nav = Navigator.of(context);
                  final authBloc = context.read<AuthBloc>();
                  final repo = context.read<SucursalRepository>();
                  final actual = auth?.sucursal?.id;
                  nav.pop();
                  final r = await repo.getSucursales();
                  final lista = r.fold((_) => <SucursalEntity>[], (l) => l);
                  final ctx = nav.context;
                  if (!ctx.mounted) return;
                  final elegida = await showModalBottomSheet<SucursalEntity>(
                    context: ctx,
                    builder: (c) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text('¿En qué sucursal vas a trabajar?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text('Sin cerrar sesión. Lo que hagas (pagos, caja, préstamos) queda en esa sucursal, sin mezclarse con las demás.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ),
                          if (lista.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No se pudo cargar la lista de sucursales')),
                          for (final s in lista)
                            ListTile(
                              leading: Icon(s.id == actual ? Icons.check_circle : Icons.store_outlined, color: s.id == actual ? Colors.green : null),
                              title: Text(s.nombre),
                              subtitle: Text(s.direccion, style: const TextStyle(fontSize: 11)),
                              onTap: () => Navigator.pop(c, s),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (elegida != null && elegida.id != actual) {
                    authBloc.add(CambiarSucursal(elegida));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Ahora trabajas en: ${elegida.nombre}')));
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: Colors.green),
              title: const Text('Cobranza de hoy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('A quién avisar: vence hoy, pronto o ya venció', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CobranzaPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.today_outlined, color: Colors.teal),
              title: const Text('Mi día', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Mi asistencia, tareas con foto y vehículos', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MiDiaPage()));
              },
            ),
            if (auth?.isAdmin == true) const AvisosGerenteTile(),
            if (auth?.isAdmin == true)
              ListTile(
                leading: const Icon(Icons.fact_check_outlined, color: Colors.teal),
                title: const Text('Operación diaria', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Cumplimiento, equipo, tareas y vehículos', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OperacionAdminPage()));
                },
              ),
            if (auth?.isAdmin == true)
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined, color: Colors.indigo),
                title: const Text('Salud del sistema', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Copias, errores, pruebas, informe del dueño', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SaludPage()));
                },
              ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Colors.deepOrange),
              title: Text(auth?.isAdmin == true ? 'Reportes de problemas' : 'Reportar un problema', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(auth?.isAdmin == true ? 'Bandeja de reportes' : 'Con fotos, audio o texto', style: const TextStyle(fontSize: 11)),
              onTap: () {
                final pantalla = homeState.selected?.nombre;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => auth?.isAdmin == true ? ReportesPage(pantalla: pantalla) : ReportarProblemaPage(pantalla: pantalla),
                  ),
                );
              },
            ),
            if (auth?.isAdmin != true)
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.deepOrange),
                title: const Text('Mis reportes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  final pantalla = homeState.selected?.nombre;
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ReportesPage(pantalla: pantalla)));
                },
              ),
            ListTile(
              leading: const Icon(Icons.system_update, color: AppColors.blue),
              title: const Text('Actualizaciones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(kBuildActual > 0 ? 'Versión instalada: $kBuildActual' : 'Versión de prueba', style: const TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ActualizacionesPage()));
              },
            ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D3EFB), Color(0xFF3F7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${auth.role?.nombre} ',
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
