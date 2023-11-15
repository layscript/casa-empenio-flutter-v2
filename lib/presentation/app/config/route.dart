import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:flutter/material.dart';

class AppRoute {
  // Todo:: Pendiente modificar
  static const initialRoute = SplashView.route;
  static final mainNavigatorKey = GlobalKey<NavigatorState>();
  static Map<String, WidgetBuilder> routes = {
    SplashView.route: (_) => const SplashView(),
    AuthView.route: (_) => const AuthView(),
    HomeView.route: (_) => const HomeView(),
  };



  static Map<String, String> getParameters(String route) =>
      Uri.dataFromString(route).queryParameters;
}
