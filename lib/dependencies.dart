part of 'main.dart';

final _client = Dio(
  BaseOptions(
    //baseUrl: 'http://161.132.38.162:31032',
    baseUrl: endPointPrincipal,
    validateStatus: (status) => (status ?? 500) < 500,
    connectTimeout: const Duration(seconds: 60000),
    receiveTimeout: const Duration(seconds: 60000),
  ),
);

final _sentry = SentryClient(
  SentryOptions(
    dsn:
        'https://2cc28a2e8d321ac9df7e149ae5e1f3f7@o4504110333558784.ingest.sentry.io/4506718787076096',
  ),
);

final UserRepository _userRepository = HttpUserRepository(
  dio: _client,
  sentry: _sentry,
);

final InterestsRepository _interestsRepository = HttpInterestsRepository(
  dio: _client,
  sentry: _sentry,
);

final ProductRepository _productRepository = HttpProductRepository(
  dio: _client,
  sentry: _sentry,
);

final CustomerRepository _customerRepository = HttpCustomerRepository(
  dio: _client,
  sentry: _sentry,
);

final LoansRepository _loansRepository = HttpLoansRepository(
  dio: _client,
  customerRepository: _customerRepository,
  sentry: _sentry,
);

final ReportsRepository _reportsRepository = HttpReportsRepository(
  dio: _client,
  sentry: _sentry,
);

final SalesRepository _salesRepository = HttpSalesRepository(
  dio: _client,
  sentry: _sentry,
);

final CategoriesRepository _categoriesRepository = HttpCategoriesRepository(
  dio: _client,
  sentry: _sentry,
);

final CajaRepository _cajaRepository = HttpCajaRepository(
  dio: _client,
  sentry: _sentry,
);

final ExpensesRepository _expensesRepository = HttpExpensesRepository(
  dio: _client,
  sentry: _sentry,
);

final HistorialRepository _historialRepository = HttpHistorialRepository(
  dio: _client,
  sentry: _sentry,
);

final MotionRepository _motionRepository = HttpMotionRepository(
  dio: _client,
  sentry: _sentry,
);

final SolicitudRepository _solicitudRepository = HttpSolicitudRepository(
  dio: _client,
  sentry: _sentry,
);

final SucursalRepository _sucursalRepository = HttpSucursalRepository(
  dio: _client,
  sentry: _sentry,
);

final PlantillaRepository _plantillaRepository = HttpPlantillaRepository(
  dio: _client,
  sentry: _sentry,
);

final ProformaRepository _proformaRepository = HttpProformaRepository(
  dio: _client,
  sentry: _sentry,
);

final AnexoRepository _anexoRepository = HttpAnexoRepository(
  dio: _client,
  sentry: _sentry,
);

final ModulosRepository _modulosRepository = HttpModulosRepository(
  dio: _client,
  sentry: _sentry,
);

final RolRepository _rolRepository = HttpRolRepository(
  dio: _client,
  sentry: _sentry,
);

void configDio(Preferences preferences) {
  _client.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (preferences.token != null) {
          options.headers['Authorization'] = 'Token ${preferences.token}';
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
