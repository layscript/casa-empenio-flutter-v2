import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

//const endPointPrincipal = 'http://161.132.38.162:31032';
const endPointPrincipal = 'http://161.132.38.162:31037';

//const endPoint = 'http://192.168.195.118:4000';
//const endPoint = 'http://192.168.18.143:4000';
//const endPointPrincipal =
//'https://casa-empenio-backend-v2-production.up.railway.app';

const endPointSucursal1 =
    'https://casa-empenio-sucursal-production.up.railway.app';

const downloadFactura =
    'https://facturacion.beyzon.dev/public/api/getFile?nombreFile=';

const appTitle = 'Casa de Empeño';
const appVersion = 'v. 2.0.0';

const invalidEmptyValue = 'Es requerido';
const invalidEmail = 'El correo electrónico no es válido';
const invalidPhone = 'Ingrese un número de teléfono válido';

final oCcy = NumberFormat("#,##0.00", "en_US");
final defaultBoxShadow = <BoxShadow>[
  BoxShadow(
    color: AppColors.lightBlack.withOpacity(0.50),
    blurRadius: 10,
  ),
];

Future<void> customLaunchUrl(Uri url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}
