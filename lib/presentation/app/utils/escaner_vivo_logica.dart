/// Lógica pura (sin cámara) del escáner en vivo: de los textos que la cámara va leyendo cuadro a cuadro,
/// decide cuál es el valor más probable de un campo (serie, placa, modelo, descripción).

/// Trozos de texto que podrían ser un dato: líneas cortas y palabras con números (series, placas, modelos).
List<String> candidatosDeTexto(String texto) {
  final out = <String>[];
  void sumar(String x) {
    if (!out.contains(x)) out.add(x);
  }

  for (final linea in texto.split(RegExp(r'[\r\n]+'))) {
    final l = linea.trim().toUpperCase();
    if (l.length >= 3 && l.length <= 40) sumar(l);
    for (final t in l.split(RegExp(r'[\s,;:]+'))) {
      final x = t.replaceAll(RegExp(r'[^A-Z0-9\-/]'), '');
      if (x.length >= 4 && x.length <= 30 && RegExp(r'\d').hasMatch(x)) sumar(x);
    }
  }
  return out.take(30).toList();
}

final _placa1 = RegExp(r'^[A-Z0-9]{3}-?[A-Z0-9]{3}$');
final _placa2 = RegExp(r'^\d{4}-?[A-Z]{2}$');

/// Puntos de un candidato para un campo. 0 = no sirve para ese campo.
int puntosDeCandidato(String campo, String c) {
  final sinEsp = c.replaceAll(' ', '');
  final tieneDigito = RegExp(r'\d').hasMatch(sinEsp);
  final tieneLetra = RegExp(r'[A-Z]').hasMatch(sinEsp);
  final esToken = !c.contains(' ');
  switch (campo) {
    case 'placa':
      if (!esToken) return 0;
      if (_placa2.hasMatch(c)) return 6;
      if (_placa1.hasMatch(c) && tieneDigito && tieneLetra) return 5;
      return 0;
    case 'serie':
      if (!esToken || c.length < 6 || c.length > 30 || !tieneDigito) return 0;
      var p = 1;
      if (c.length >= 8) p += 2;
      if (tieneLetra) p += 2;
      if (c.length > 20) p -= 1;
      return p;
    case 'modelo':
      if (c.contains('MODEL')) return 0; // es la etiqueta, no el valor
      if (!esToken || c.length < 3 || c.length > 25 || !tieneDigito) return 0;
      return tieneLetra ? 3 : 1;
    default: // descripcion
      if (c.length < 4 || c.length > 40) return 0;
      return c.length >= 8 ? 2 : 1;
  }
}

/// Valor que sigue a una etiqueta ("MODEL: ABC-123", "S/N XYZ") en una línea, si lo hay.
String? valorTrasEtiqueta(String campo, String linea) {
  final l = linea.toUpperCase();
  final claves = campo == 'serie'
      ? RegExp(r'(?:S/N|SN|SERIAL(?: NO\.?| NUMBER)?|SERIE|IMEI)\s*[:#.]?\s*([A-Z0-9\-/]{6,30})')
      : campo == 'modelo'
          ? RegExp(r'(?:MODEL(?:O)?(?: NO\.?| NUMBER)?)\s*[:#.]?\s*([A-Z0-9\-/]{3,25})')
          : null;
  final m = claves?.firstMatch(l);
  return m?.group(1);
}

/// El mejor valor visto hasta ahora. [vistos] cuenta en cuántos cuadros apareció cada texto;
/// un texto debe verse al menos 2 veces para proponerse (así no salta con lecturas sueltas).
String? proponerCampo(String campo, Map<String, int> vistos) {
  String? mejor;
  var mejorPts = 0;
  vistos.forEach((c, veces) {
    if (veces < 2) return;
    final base = puntosDeCandidato(campo, c);
    if (base == 0) return;
    final pts = base * (veces > 5 ? 5 : veces) + (campo == 'descripcion' ? 0 : c.length ~/ 4);
    if (pts > mejorPts) {
      mejorPts = pts;
      mejor = c;
    }
  });
  return mejor;
}

/// Anota lo leído en un cuadro: cada candidato suma una vez por cuadro. Lo que viene tras una etiqueta ("S/N ...") vale más.
void anotarCuadro(String campo, String texto, Map<String, int> vistos) {
  for (final c in candidatosDeTexto(texto)) {
    vistos[c] = (vistos[c] ?? 0) + 1;
  }
  for (final linea in texto.split(RegExp(r'[\r\n]+'))) {
    final v = valorTrasEtiqueta(campo, linea);
    if (v != null) vistos[v] = (vistos[v] ?? 0) + 3; // vale por 3 cuadros
  }
}
