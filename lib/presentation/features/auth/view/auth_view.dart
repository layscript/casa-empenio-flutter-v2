import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/actualizaciones.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthView extends StatefulWidget {
  const AuthView({Key? key}) : super(key: key);
  static const route = 'auth';

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool emailIsValid = false;
  bool passwordIsValid = false;
  String? _estadoServidor; // null = verificando
  bool _servidorOk = false;
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    _verificar();
    // También se avisa de actualizaciones desde esta pantalla, por si no se puede iniciar sesión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) avisarActualizacion(context);
    });
  }

  Future<void> _verificar() async {
    setState(() => _verificando = true);
    final r = await verificarServidor();
    if (mounted) {
      setState(() {
        _servidorOk = r == null;
        _estadoServidor = r ?? 'Servidor funcionando${versionServidor.isNotEmpty ? ' · versión $versionServidor' : ' · versión antigua'}';
        _verificando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Keyboard.unfocus(context),
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.runtimeType == AuthLoading) {
              OverlayLoader.show(context);
            } else {
              OverlayLoader.hide();
              if (state is AuthError) {
                ErrorSnackbar.show(context, state.message);
              }
            }
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipPath(
                      clipper: CustomClipperPath(),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        color: const Color.fromARGB(255, 7, 107, 75),
                      ),
                    ),
                    Positioned(
                      top: 110,
                      right: MediaQuery.of(context).size.width * 0.35,
                      child: Image.asset(
                        AppIcons.logoEmpenio,
                        width: 120,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextFormField(
                          controller: emailCtrl,
                          labelText: 'Usuario',
                          validator: (value) {
                            return value!.isEmpty ? invalidEmptyValue : null;
                          },
                          isValid: (value) =>
                              setState(() => emailIsValid = value),
                        ),
                        const SizedBox(height: 20),
                        AppTextFormField(
                          obscureText: true,
                          controller: passwordCtrl,
                          labelText: 'Contraseña',
                          validator: (value) {
                            return value!.isEmpty ? invalidEmptyValue : null;
                          },
                          isValid: (value) =>
                              setState(() => passwordIsValid = value),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          onPressed: emailIsValid && passwordIsValid
                              ? () {
                                  context.read<AuthBloc>().add(
                                        LogIn(
                                          username: emailCtrl.text,
                                          password: passwordCtrl.text,
                                        ),
                                      );
                                }
                              : null,
                          child: const Text(
                            'Iniciar sesión',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(appVersion),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _verificando ? Colors.grey.shade100 : (_servidorOk ? Colors.green.shade50 : Colors.red.shade50), borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            Row(children: [
                              Icon(_verificando ? Icons.sync : (_servidorOk ? Icons.check_circle : Icons.error), size: 20, color: _verificando ? Colors.grey : (_servidorOk ? Colors.green : Colors.red)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_verificando ? 'Verificando el servidor…' : (_estadoServidor ?? ''), style: const TextStyle(fontSize: 12))),
                            ]),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              TextButton.icon(onPressed: _verificando ? null : _verificar, icon: const Icon(Icons.refresh, size: 16), label: const Text('Verificar', style: TextStyle(fontSize: 12))),
                              TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActualizacionesPage())), icon: const Icon(Icons.system_update, size: 16), label: const Text('Actualizaciones', style: TextStyle(fontSize: 12))),
                            ]),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        const TermsPrivacy(),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomClipperPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;

    final path = Path();
    path.lineTo(0, h);
    path.quadraticBezierTo(
      w * 0.5,
      h - 40,
      w,
      h,
    );

    path.lineTo(w, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
