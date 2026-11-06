import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart' show Preferences;
import 'package:casa_empenio_pe/presentation/app/utils/actualizaciones.dart';
import 'package:casa_empenio_pe/presentation/app/utils/salud_view.dart' show recordarUsuarioParaErrores;
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDiaSesion = 'dia_sesion_lima';

/// Fecha de hoy en hora de Lima (UTC-5), formato aaaa-mm-dd.
String hoyLima() {
  final d = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Se llama al cerrar sesión: el próximo ingreso marcará el día nuevo.
Future<void> olvidarDiaSesion() async {
  try {
    (await SharedPreferences.getInstance()).remove(_kDiaSesion);
  } catch (_) {}
}

/// Mientras la persona trabaja, vigila dos cosas:
///  1. Que no haya pasado la medianoche (hora de Lima): si cambió el día, pide iniciar sesión otra vez.
///  2. Que no haya una versión nueva de la app: si la hay, muestra una franja para actualizar.
class VigilanteSesion extends StatefulWidget {
  const VigilanteSesion({super.key, required this.child});
  final Widget child;

  @override
  State<VigilanteSesion> createState() => _VigilanteSesionState();
}

class _VigilanteSesionState extends State<VigilanteSesion> with WidgetsBindingObserver {
  Timer? _reloj;
  int _vueltas = 0;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      recordarUsuarioParaErrores(context.read<Preferences>().token);
      _revisarDia();
    });
    // Cada minuto revisa el día; cada 10 minutos, si hay actualización.
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) {
      _revisarDia();
      _vueltas++;
      if (_vueltas % 10 == 0 && mounted) avisarActualizacion(context, banner: true);
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revisarDia();
      if (mounted) avisarActualizacion(context, banner: true);
    }
  }

  Future<void> _revisarDia() async {
    if (_cerrando || !mounted) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final hoy = hoyLima();
      final guardado = sp.getString(_kDiaSesion);
      if (guardado == null) {
        await sp.setString(_kDiaSesion, hoy);
        return;
      }
      if (guardado == hoy || !mounted) return;
      _cerrando = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.wb_sunny_outlined, size: 36),
          title: const Text('Es un nuevo día'),
          content: const Text(
              'Por seguridad, la sesión se cierra cada día a la medianoche (hora de Lima).\n\n'
              'Inicia sesión con tu propia cuenta para empezar. Lo que estabas registrando no se pierde.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iniciar sesión')),
          ],
        ),
      );
      await olvidarDiaSesion();
      if (mounted) context.read<AuthBloc>().add(SignOff());
    } catch (_) {
      _cerrando = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
