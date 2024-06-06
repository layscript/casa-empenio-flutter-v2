import 'package:casa_empenio_pe_dev/presentation/features/features.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/feature/loans_step/views/loans_step_view.dart';
import 'package:flutter/material.dart';

class AppRoute {
  static const initialRoute = SplashView.route;
  static final mainNavigatorKey = GlobalKey<NavigatorState>();
  static Map<String, WidgetBuilder> routes = {
    SplashView.route: (_) => const SplashView(),
    AuthView.route: (_) => const AuthView(),
    HomeView.route: (_) => const HomeView(),
    LoansStepView.route: (_) => const LoansStepView(),
  };

  static Map<String, String> getParameters(String route) =>
      Uri.dataFromString(route).queryParameters;
}
