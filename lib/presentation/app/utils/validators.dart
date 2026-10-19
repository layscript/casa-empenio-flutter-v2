import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String setTimeToLocal(String hora) {
  try {
    final time = DateFormat('hh:mm:ss a').parse(hora);
    return DateFormat('hh:mm:ss a', 'es_ES').format(time);
  } catch (_) {
    return hora;
  }
}

/// Convierte una fecha ISO del servidor (UTC) a hora de Perú (UTC-5, sin
/// horario de verano). No depende de la zona horaria del celular.
DateTime? fechaPeru(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  // Si el texto no trae zona horaria, es hora del servidor (UTC)
  var texto = iso.trim().replaceFirst(' ', 'T');
  if (!RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(texto)) texto = '${texto}Z';
  final dt = DateTime.tryParse(texto);
  if (dt == null) return null;
  final utc = dt.isUtc ? dt : dt.toUtc();
  return utc.subtract(const Duration(hours: 5));
}

/// Ej.: 18/10/2026 - 11:47 PM
String setDateTimeToLocal(String? fecha) {
  final d = fechaPeru(fecha);
  if (d == null) return '-';
  return DateFormat('dd/MM/yyyy - hh:mm a').format(d);
}

/// Ej.: 18/10/2026
String fechaCortaPeru(String? fecha) {
  final d = fechaPeru(fecha);
  if (d == null) return '-';
  return DateFormat('dd/MM/yyyy').format(d);
}

final removeBlankSpaces = [
  FilteringTextInputFormatter.deny(
    RegExp(r'\s\b|\b\s'),
  )
];

bool validatorEmail(String value) {
  const pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  final reg = RegExp(pattern);
  return reg.hasMatch(value);
}

String generateIDFromDateTime() {
  var now = DateTime.now();
  var formatter = DateFormat('yyyyMMddHHmmss');
  String formattedDate = formatter.format(now);

  // Agregar un identificador único, por ejemplo, un número aleatorio
  var uniqueId = UniqueKey().toString();

  // Combinar la fecha formateada con el identificador único
  String generatedID = '${formattedDate}_$uniqueId';

  return generatedID;
}
