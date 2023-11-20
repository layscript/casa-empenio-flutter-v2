import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

const endPoint = 'http://161.132.38.162:31032';
const appTitle = 'Casa de Empeño';
const appVersion = 'v. 1.0.0';

const invalidEmptyValue = 'Es requerido';
const invalidEmail = 'El correo electrónico no es válido';
const invalidPhone = 'Ingrese un número de teléfono válido';

final defaultBoxShadow = <BoxShadow>[
  BoxShadow(
    color: AppColors.lightBlack.withOpacity(0.50),
    blurRadius: 10,
  ),
];
