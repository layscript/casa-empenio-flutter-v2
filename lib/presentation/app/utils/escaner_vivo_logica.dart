import 'package:casa_empenio_pe/presentation/app/utils/dni_logica.dart' show LineaGeo;

/// Lógica pura (sin cámara) del escáner en vivo: de los textos que la cámara va leyendo cuadro a cuadro,
/// decide cuál es el valor más probable de un campo (serie, placa, modelo, descripción).

/// Trozos de texto que podrían ser un dato: líneas cortas y palabras con números (series, placas, modelos).
List<String> candidatosDeTexto(String texto, {bool ventanas = false}) {
  final out = <String>[];
  void sumar(String x) {
    if (!out.contains(x)) out.add(x);
  }

  final lineas = texto.split(RegExp(r'[\r\n]+')).map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList();
  for (var i = 0; i < lineas.length; i++) {
    final l = lineas[i];
    if (l.length >= 3 && l.length <= 40) sumar(l);
    if (ventanas) {
      // Modelos con nombre ("IDEAPAD SLIM 3 15IAH8", "GALAXY S24"): grupos de 2 a 4 palabras seguidas y línea + línea de abajo.
      final pal = l.split(RegExp(r'\s+')).map((e) => e.replaceAll(RegExp(r'[^A-Z0-9\-/.]'), '')).where((e) => e.isNotEmpty).toList();
      for (var a = 0; a < pal.length; a++) {
        for (var n = 2; n <= 4 && a + n <= pal.length; n++) {
          final w = pal.sublist(a, a + n).join(' ');
          if (w.length <= 32) sumar(w);
        }
      }
      if (i + 1 < lineas.length) {
        final j = '$l ${lineas[i + 1]}';
        if (j.length <= 32) sumar(j);
      }
    }
    for (final t in l.split(RegExp(r'[\s,;:]+'))) {
      final x = t.replaceAll(RegExp(r'[^A-Z0-9\-/]'), '');
      if (x.length >= 4 && x.length <= 30 && RegExp(r'\d').hasMatch(x)) sumar(x);
    }
  }
  return out.take(ventanas ? 90 : 30).toList();
}

const _series = {
  'IDEAPAD', 'THINKPAD', 'THINKBOOK', 'LEGION', 'YOGA', 'LOQ', 'VICTUS', 'PAVILION', 'OMEN', 'ENVY', 'SPECTRE',
  'PROBOOK', 'ELITEBOOK', 'INSPIRON', 'LATITUDE', 'VOSTRO', 'XPS', 'ALIENWARE', 'MACBOOK', 'IPHONE', 'IPAD',
  'GALAXY', 'REDMI', 'POCO', 'NOTE', 'MOTO', 'NITRO', 'ASPIRE', 'SWIFT', 'PREDATOR', 'TUF', 'ROG', 'VIVOBOOK',
  'ZENBOOK', 'EXPERTBOOK', 'SURFACE', 'PLAYSTATION', 'XBOX', 'SWITCH', 'TECNO', 'SPARK', 'INFINIX', 'PAD', 'TAB',
  'SLIM', 'GAMING', 'FLEX', 'CHROMEBOOK', 'MAGIC', 'PURA', 'MATE', 'NOVA', 'HONOR', 'REALME', 'VIVO', 'OPPO',
};
const _marcas = {
  'LENOVO', 'HP', 'DELL', 'ASUS', 'ACER', 'SAMSUNG', 'APPLE', 'MSI', 'LG', 'SONY', 'JBL', 'CANON', 'NIKON', 'EPSON',
  'XIAOMI', 'HUAWEI', 'MOTOROLA', 'NOKIA', 'TOSHIBA', 'HONOR', 'HAIER', 'PHILIPS', 'PANASONIC', 'BOSE', 'DJI',
};
const _ruidoModelo = {
  'INTEL', 'CORE', 'CELERON', 'PENTIUM', 'RYZEN', 'AMD', 'WINDOWS', 'MADE', 'IN', 'CHINA', 'VIETNAM', 'MEMORY', 'PROCESSOR',
  'INSIDE', 'INPUT', 'OUTPUT', 'WARNING', 'CAUTION', 'SERIAL', 'FCC', 'RAM', 'SSD', 'DDR4', 'DDR5', 'HDD', 'LISTED',
  'CLASS', 'VOLT', 'HZ', 'GB', 'TB', 'NVME', 'PCIE', 'USB', 'HDMI', 'WIFI', 'BLUETOOTH', 'BATTERY', 'ADAPTER', 'POWER',
  'ENERGY', 'STAR', 'REGULATORY', 'COMPLIANT', 'CERTIFIED', 'NO', 'NUMBER', 'S/N', 'SN', 'PN', 'P/N', 'MTM', 'DC', 'AC',
  'THE', 'AND', 'FOR', 'WITH', 'PERU', 'MEXICO', 'TAIWAN', 'INDONESIA', 'INDIA', 'BRAZIL', 'LAPTOP', 'NOTEBOOK',
};

/// Puntos de un texto como modelo: nombres de serie ("IDEAPAD SLIM 3 15IAH8", "GALAXY S24") y códigos ("SM-A155M").
int _puntosModelo(String c) {
  if (c.startsWith('MODEL')) return 0; // es la etiqueta, no el valor
  if (c.length < 3 || c.length > 32) return 0;
  final pal = c.split(' ').where((e) => e.isNotEmpty).toList();
  if (pal.isEmpty || pal.length > 5) return 0;
  if (pal.any(_ruidoModelo.contains)) return 0;
  final tieneDigito = RegExp(r'\d').hasMatch(c);
  final serie = pal.any(_series.contains);
  final marca = pal.any(_marcas.contains);
  final codigo = pal.any((p) => RegExp(r'\d').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p) && p.length >= 3);
  if (!serie && !marca && !tieneDigito) return 0; // palabras sueltas sin pista: no son un modelo
  if (!serie && !codigo) return pal.length == 1 ? (tieneDigito ? 1 : 0) : (marca && tieneDigito ? 2 : 1);
  var p = 0;
  if (serie) p += 4;
  if (codigo) p += 3;
  if (marca) p += 1;
  if (serie && tieneDigito) p += 1;
  return p;
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
      return _puntosModelo(c);
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
          ? RegExp(r'(?:MODEL(?:O)?(?: NAME| NO\.?| NUMBER)?|PRODUCT NAME|NOMBRE DEL PRODUCTO)\s*[:#.]?\s*([A-Z0-9][A-Z0-9\-/ ]{2,28})')
          : null;
  final m = claves?.firstMatch(l);
  return m?.group(1)?.trim();
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
  for (final c in candidatosDeTexto(texto, ventanas: campo == 'modelo')) {
    vistos[c] = (vistos[c] ?? 0) + 1;
  }
  for (final linea in texto.split(RegExp(r'[\r\n]+'))) {
    final v = valorTrasEtiqueta(campo, linea);
    if (v != null) vistos[v] = (vistos[v] ?? 0) + 3; // vale por 3 cuadros
  }
}

/// Texto de las líneas que caen dentro de un recuadro (en coordenadas de la imagen). Se ordenan de arriba a abajo
/// y de izquierda a derecha. Una línea cuenta si al menos [minSolape] de su área está dentro del recuadro.
String textoDeArea(List<LineaGeo> lineas, double izq, double arriba, double der, double abajo, {double minSolape = 0.3}) {
  final dentro = <LineaGeo>[];
  for (final l in lineas) {
    final ancho = l.ancho <= 0 ? 1.0 : l.ancho;
    final alto = l.alto <= 0 ? 1.0 : l.alto;
    final w = (l.izq + ancho < der ? l.izq + ancho : der) - (l.izq > izq ? l.izq : izq);
    final h = (l.arriba + alto < abajo ? l.arriba + alto : abajo) - (l.arriba > arriba ? l.arriba : arriba);
    if (w <= 0 || h <= 0) continue;
    if (w * h / (ancho * alto) >= minSolape) dentro.add(l);
  }
  dentro.sort((a, b) {
    final dy = a.arriba - b.arriba;
    if ((dy).abs() > (a.alto < b.alto ? a.alto : b.alto) * 0.6) return dy < 0 ? -1 : 1;
    return a.izq.compareTo(b.izq);
  });
  return dentro.map((e) => e.texto.trim()).where((e) => e.isNotEmpty).join(' ').toUpperCase();
}

/// La línea tocada (o la más cercana dentro de [margen] píxeles de la imagen).
String textoDeToque(List<LineaGeo> lineas, double x, double y, {double margen = 30}) {
  LineaGeo? mejor;
  var mejorD = double.infinity;
  for (final l in lineas) {
    final dx = x < l.izq ? l.izq - x : (x > l.izq + l.ancho ? x - (l.izq + l.ancho) : 0.0);
    final dy = y < l.arriba ? l.arriba - y : (y > l.arriba + l.alto ? y - (l.arriba + l.alto) : 0.0);
    final d = dx * dx + dy * dy;
    if (d < mejorD) {
      mejorD = d;
      mejor = l;
    }
  }
  if (mejor == null || mejorD > margen * margen) return '';
  return mejor.texto.trim().toUpperCase();
}
