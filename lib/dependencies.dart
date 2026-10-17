part of 'main.dart';

final _client = Dio(
  BaseOptions(
    //baseUrl: 'http://161.132.38.162:31032',
    baseUrl: endPointPrincipal,
    //validateStatus: (status) => (status ?? 500) < 500,
    connectTimeout: const Duration(seconds: 90000),
    receiveTimeout: const Duration(seconds: 90000),
  ),
);

final UserRepository _userRepository = HttpUserRepository(
  dio: _client,
);

final InterestsRepository _interestsRepository = HttpInterestsRepository(
  dio: _client,
);

final ProductRepository _productRepository = HttpProductRepository(
  dio: _client,
);

final CustomerRepository _customerRepository = HttpCustomerRepository(
  dio: _client,
);

final LoansRepository _loansRepository = HttpLoansRepository(
  dio: _client,
  customerRepository: _customerRepository,
);

final ReportsRepository _reportsRepository = HttpReportsRepository(
  dio: _client,
);

final SalesRepository _salesRepository = HttpSalesRepository(
  dio: _client,
);

final CategoriesRepository _categoriesRepository = HttpCategoriesRepository(
  dio: _client,
);

final CajaRepository _cajaRepository = HttpCajaRepository(
  dio: _client,
);

final ExpensesRepository _expensesRepository = HttpExpensesRepository(
  dio: _client,
);

final HistorialRepository _historialRepository = HttpHistorialRepository(
  dio: _client,
);

final MotionRepository _motionRepository = HttpMotionRepository(
  dio: _client,
);

final SolicitudRepository _solicitudRepository = HttpSolicitudRepository(
  dio: _client,
);

final SucursalRepository _sucursalRepository = HttpSucursalRepository(
  dio: _client,
);

final PlantillaRepository _plantillaRepository = HttpPlantillaRepository(
  dio: _client,
);

final ProformaRepository _proformaRepository = HttpProformaRepository(
  dio: _client,
);

final AnexoRepository _anexoRepository = HttpAnexoRepository(
  dio: _client,
);

final ModulosRepository _modulosRepository = HttpModulosRepository(
  dio: _client,
);

final RolRepository _rolRepository = HttpRolRepository(
  dio: _client,
);

void configDio(Preferences preferences) {
  _client.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (preferences.token != null) {
          options.headers['Authorization'] = 'Token ${preferences.token}';
        }
        // Identifica al usuario para la auditoría del servidor
        final usuarioActual = preferences.token;
        if (usuarioActual != null) {
          options.headers['x-usuario-id'] = usuarioActual.id.toString();
          options.headers['x-usuario-nombre'] = Uri.encodeComponent(
              '${usuarioActual.nombre ?? ''} ${usuarioActual.apellido ?? ''}'
                  .trim());
        }

        log('********* ${options.uri.toString()} *********');
        log('httpRequest - data: ${options.data}');
        log('httpRequest - headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        log('********* ${response.realUri.toString()} *********');
        log('httpResponse - statusCode: ${response.statusCode}');
        log('httpResponse - response: ${response.data}');
        handler.next(response);
      },
      onError: (e, handler) {
        log('********* ${e.requestOptions.uri.toString()} *********');
        log('httpError: $e');
        handler.next(e);
      },
    ),
  );
}
