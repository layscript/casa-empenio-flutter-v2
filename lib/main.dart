import 'dart:developer';

import 'package:casa_empenio_pe/app.dart';
import 'package:casa_empenio_pe/bootstrap.dart';
import 'package:casa_empenio_pe/data/data.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final Preferences localPreferences = LocalPreferences(sharedPreferences);
  configDio(localPreferences);
  Bloc.observer = AppBlocObserver();
  runApp(
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
  );
}
