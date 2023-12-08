part of 'main.dart';

final _client = Dio(
  BaseOptions(
    //baseUrl: 'http://161.132.38.162:31032',
    baseUrl: endPoint,
    validateStatus: (status) => (status ?? 500) < 500,
    connectTimeout: const Duration(seconds: 60000),
    receiveTimeout: const Duration(seconds: 60000),
  ),
);

final UserRepository _userRepository = HttpUserRepository(dio: _client);

final InterestsRepository _interestsRepository =
    HttpInterestsRepository(dio: _client);

final ProductRepository _productRepository =
    HttpProductRepository(dio: _client);

final CustomerRepository _customerRepository = HttpCustomerRepository(
  dio: _client,
);

final LoansRepository _loansRepository = HttpLoansRepository(
  dio: _client,
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

/* final _firebase = FirebaseAuth.instance;
final _google = GoogleSignIn();
final _facebook = FacebookLogin();
final _analytics = FirebaseAnalytics.instance;
final _observerAnalytics = FirebaseAnalyticsObserver(analytics: _analytics);

final AuthRepository _authRepository = HttpAuthRepository(_client, _sentry);
final ProfileRepository _profileRepository =
    HttpProfileRepository(_client, _sentry);
final BankAccountRepository _bankAccountRepository =
    HttpBankAccountRepository(_client, _sentry);
final UploadFileRepository _uploadFileRepository =
    HttpUploadFileRepository(_client, _commonClient, _sentry);
final QuotationRepository _quotationRepository =
    HttpQuotationRepository(_client, _sentry);
final OperationRepository _operationRepository =
    HttpOperationRepository(_client, _sentry);
final AnalyticsRepository _analyticsRepository =
    FirebaseAnalyticsRepository(_analytics);
final CheckPolicyRepository _checkPolicyRepository =
    HttpCheckPolicyRepository(_client, _sentry);
final NiubizRepository _niubizRepository =
    HttpNiubizRepository(_client, niubizScriptProd, niubizOriginProd, _sentry);

final AppVersionRepository _appVersionRepository =
    HttpAppVersionRepository(_client, _sentry);
final AlertBankRepository _alertBankRepository =
    HttpAlertBankRepository(_client, _sentry);
final RecommendRepository _recommendRepository =
    HttpRecommendRepository(_client, _sentry);
final FeatureFlagsRepository _featureFlagsRepository =
    HttpFeatureFlagsRepository(_client, _sentry);

final RextiePointsRepository _rextiePointsRepository =
    HttpRextiePointsRepository(_client, _sentry);

final NotificationRepository _notificationRepository =
    HttpNotificationRepository(_client, _sentry);

final OneSignalRepository _oneSignalRepository =
    HttpOneSignalRepository(OneSignal());

final _appleSignIn = AppleSignIn();

final AppReviewRepository _appReviewRepository =
    InAppReviewService(InAppReview.instance);

final RegionRepository _regionRepository =
    HttpRegionRepository(_client, _sentry);

final _flavor = Flavors('Production');
bool _flagHuawei = false; // Cambiar al true para probar en huawei

const _urlRextiePoints = 'https://webapp.rextie.com/rextie-puntos'; */

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
