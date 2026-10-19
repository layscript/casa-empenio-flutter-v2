import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);
  static const route = 'home';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(RefreshDataUser());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<Preferences>().token;
    final preferences = context.watch<Preferences>();

    final ahora = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    const dias = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
      'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final fechaHoy =
        '${dias[ahora.weekday - 1]} ${ahora.day} de ${meses[ahora.month - 1]}';
    final h = ahora.hour;
    final saludo = h < 12
        ? 'Buenos días'
        : (h < 19 ? 'Buenas tardes' : 'Buenas noches');

    return SingleChildScrollView(
      child: Column(
        children: [
          // ---- Tarjeta de bienvenida ----
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D3EFB), Color(0xFF3F7BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$saludo, ${auth?.nombre ?? ''} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${preferences.token?.sucursal?.nombre ?? ''}'
                  '${auth?.role?.nombre != null ? '  ·  ${auth?.role?.nombre}' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  fechaHoy,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 18, color: AppColors.secondaryText),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '¿Qué quieres hacer hoy? Toca un módulo para entrar.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (auth?.role?.modulos != null)
            GridView.count(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              crossAxisCount: 2,
              childAspectRatio: 0.95,
              children: auth?.role?.modulos?.map((e) {
                    if (e.id == 19 || e.id == 18 || e.id == 17 || e.id == 16) {
                      return const SizedBox();
                    } else {
                      return _ItemGrid(
                        onTap: () {
                          preferences.setRefresh(true);
                          context.read<HomeBloc>().add(
                                GoToPage(e),
                              );
                        },
                        text: e.nombre.toUpperCase(),
                        descripcion: descripcionModulo(e.nombre),
                        color: colorModulo(e.id),
                        icon: getIcon(e.id),
                      );
                    }
                  }).toList() ??
                  [],
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// Explicación corta de cada módulo (según su nombre) para que sea didáctico.
String descripcionModulo(String nombre) {
  final n = nombre.toLowerCase();
  const mapa = <String, String>{
    'expediente': 'Contrato, firma y huella digital',
    'auditor': 'Quién hizo qué en la app',
    'bitacora': 'Quién hizo qué en la app',
    'administraci': 'Usuarios, sucursales y ajustes',
    'perdon': 'Intereses o deudas perdonadas',
    'proforma': 'Cotizaciones y notas de venta',
    'caja': 'Abrir, cerrar y ver el dinero del día',
    'gasto': 'Anota lo que gastas',
    'venta': 'Artículos vendidos',
    'prést': 'Registra y controla préstamos',
    'prest': 'Registra y controla préstamos',
    'interes': 'Cobro de intereses',
    'interés': 'Cobro de intereses',
    'pago': 'Pagos y cuotas',
    'reporte': 'Resúmenes y descargas',
    'histor': 'Movimientos anteriores',
    'categor': 'Tipos de artículos',
    'producto': 'Artículos en custodia',
    'usuario': 'Personas con acceso',
    'rol': 'Puestos y permisos',
    'plantilla': 'Modelos de documentos',
    'anexo': 'Documentos del préstamo',
    'notif': 'Avisos importantes',
    'cliente': 'Datos de tus clientes',
  };
  for (final e in mapa.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return 'Toca para abrir';
}

Color colorModulo(int id) {
  const colores = [
    Color(0xFF0D3EFB),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFF9333EA),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFFCA8A04),
    Color(0xFF475569),
  ];
  return colores[id.abs() % colores.length];
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.onTap,
    required this.text,
    required this.descripcion,
    required this.color,
    required this.icon,
  });

  final void Function()? onTap;
  final String text;
  final String descripcion;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(icon, size: 24, color: color),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
