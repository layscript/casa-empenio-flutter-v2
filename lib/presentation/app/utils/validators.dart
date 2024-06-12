import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String setTimeToLocal(String hora) {
  final time = DateFormat('hh:mm:ss a').parse(hora).toLocal();
  String formattedTime = DateFormat('hh:mm:ss a', 'es_ES').format(time);
  return formattedTime;
}

String setDateTimeToLocal(String fecha) {
  return DateFormat('dd/MM/yyyy - hh:mm')
      .format(DateTime.parse(fecha).toLocal());
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
