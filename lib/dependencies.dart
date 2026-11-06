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
        // Vista previa del administrador: solo se puede mirar, nada se guarda.
        if (VistaPrevia.usuario != null && options.method.toUpperCase() != 'GET') {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 400,
                data: {'message': 'Estás en VISTA PREVIA: solo puedes mirar. Toca "Salir" en la franja naranja para volver a ser administrador y poder guardar.'},
              ),
            ),
            true,
          );
        }
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
        _ofrecerSolicitudPermiso(e);
        handler.next(e);
      },
    ),
  );
}

bool _dialogoPermisoAbierto = false;

/// Si el servidor bloqueó la acción por permisos, ofrece pedir autorización al administrador.
Future<void> _ofrecerSolicitudPermiso(DioException e) async {
  try {
    final data = e.response?.data;
    if (e.response?.statusCode != 403 ||
        data is! Map ||
        data['code'] != 'PERMISO_DENEGADO') {
      return;
    }
    final ctx = AppRoute.mainNavigatorKey.currentContext;
    if (ctx == null || _dialogoPermisoAbierto) return;
    _dialogoPermisoAbierto = true;
    bool autonomo = false;
    try {
      final r = await _client.get<dynamic>('/acceso/autonomia/yo');
      final b = r.data is Map ? r.data['body'] : null;
      autonomo = b is Map && b['autonomo'] == true;
    } catch (_) {}
    final motivo = TextEditingController();
    showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        title: const Text('No tiene permiso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((data['message'] ?? 'Su puesto no puede hacer esta acción.')
                .toString()),
            const SizedBox(height: 12),
            Text(autonomo
                ? 'Si el administrador no responde, puede hacerlo ahora escribiendo el motivo. Queda registrado y se le avisa al administrador.'
                : '¿Desea pedir autorización al administrador?'),
            TextField(
              controller: motivo,
              decoration: InputDecoration(labelText: autonomo ? 'Motivo (obligatorio, mínimo 10 letras)' : 'Motivo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, null),
              child: const Text('Ahora no')),
          if (autonomo)
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(dctx, 'ahora'),
                child: const Text('Hacerlo ahora')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dctx, 'pedir'),
              child: const Text('Pedir autorización')),
        ],
      ),
    ).then((pedir) async {
      _dialogoPermisoAbierto = false;
      if (pedir == null) return;
      String aviso;
      try {
        if (pedir == 'ahora') {
          await _client.post('/acceso/solicitudes/autoaprobar', data: {
            'modulo': data['modulo'],
            'accion': data['accion'],
            'motivo': motivo.text.trim(),
          });
          aviso = 'Listo: ya puede hacerlo. Vuelva a tocar la acción (vale 15 minutos y una sola vez). El administrador recibirá el aviso.';
        } else {
          await _client.post('/acceso/solicitudes', data: {
            'modulo': data['modulo'],
            'accion': data['accion'],
            'motivo': motivo.text.trim(),
          });
          aviso =
              'Solicitud enviada. Avise al administrador para que la apruebe y luego vuelva a intentarlo.';
        }
      } on DioException catch (err) {
        final m = err.response?.data;
        aviso = (m is Map && m['message'] != null) ? m['message'].toString() : 'No se pudo enviar. Intente de nuevo.';
      } catch (_) {
        aviso = 'No se pudo enviar la solicitud. Intente de nuevo.';
      }
      final c2 = AppRoute.mainNavigatorKey.currentContext;
      if (c2 != null) {
        ScaffoldMessenger.maybeOf(c2)?.showSnackBar(SnackBar(content: Text(aviso)));
      }
    });
  } catch (_) {
    _dialogoPermisoAbierto = false;
  }
}
