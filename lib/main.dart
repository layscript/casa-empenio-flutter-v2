import 'dart:developer';

import 'package:casa_empenio_pe/app.dart';
import 'package:casa_empenio_pe/bootstrap.dart';
import 'package:casa_empenio_pe/data/data.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final Preferences localPreferences = LocalPreferences(sharedPreferences);
  configDio(localPreferences);
  Bloc.observer = AppBlocObserver();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://2cc28a2e8d321ac9df7e149ae5e1f3f7@o4504110333558784.ingest.sentry.io/4506718787076096';
      options.enableAutoSessionTracking = true;
      options.inAppExcludes;
      options.useFlutterBreadcrumbTracking();
    },
    appRunner: () => runApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => localPreferences,
          ),
          RepositoryProvider(
            create: (context) => _userRepository,
          ),
          RepositoryProvider(
            create: (context) => _interestsRepository,
          ),
          RepositoryProvider(
            create: (context) => _productRepository,
          ),
          RepositoryProvider(
            create: (context) => _customerRepository,
          ),
          RepositoryProvider(
            create: (context) => _loansRepository,
          ),
          RepositoryProvider(
            create: (context) => _reportsRepository,
          ),
          RepositoryProvider(
            create: (context) => _salesRepository,
          ),
          RepositoryProvider(
            create: (context) => _categoriesRepository,
          ),
          RepositoryProvider(
            create: (context) => _cajaRepository,
          ),
          RepositoryProvider(
            create: (context) => _expensesRepository,
          ),
          RepositoryProvider(
            create: (context) => _historialRepository,
          ),
          RepositoryProvider(
            create: (context) => _motionRepository,
          ),
          RepositoryProvider(
            create: (context) => _solicitudRepository,
          ),
          RepositoryProvider(
            create: (context) => _sentry,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => AuthBloc(
                userRepository: _userRepository,
                preferences: localPreferences,
              ),
            ),
          ],
          child: const App(),
        ),
      ),
    ),
  );
}
