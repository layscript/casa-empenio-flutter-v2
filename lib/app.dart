import 'package:casa_empenio_pe_dev/presentation/app/assets/theme.dart';
import 'package:casa_empenio_pe_dev/presentation/app/config/config.dart';
import 'package:casa_empenio_pe_dev/presentation/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final mainNavigatorKey = AppRoute.mainNavigatorKey;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        switch (state.runtimeType) {
          case Authenticated:
            mainNavigatorKey.currentState?.pushNamedAndRemoveUntil(
              HomeView.route,
              (route) => false,
            );
            break;

          case UnAuthenticated:
            mainNavigatorKey.currentState?.pushNamedAndRemoveUntil(
              AuthView.route,
              (route) => false,
            );
            break;
        }
      },
      child: MaterialApp(
        navigatorKey: mainNavigatorKey,
        title: appTitle,
        // themeMode: ThemeMode.dark,
        // darkTheme: ThemeData.dark(),
        //theme: ThemeData.dark(),
        theme: buildTheme(context),
        themeMode: ThemeMode.light,
        //theme: buildTheme(context),
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'ES'),
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        //supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: AppRoute.initialRoute,
        routes: AppRoute.routes,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaleFactor: 1,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
