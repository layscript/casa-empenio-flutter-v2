/// Lógica pura (sin cámara) para leer un DNI peruano a partir del texto que reconoce la cámara.

class DatosDni {
  const DatosDni({this.dni = '', this.apellidos = '', this.nombres = '', this.domicilio = ''});
  final String domicilio;
  final String dni;
  final String apellidos;
  final String nombres;

  bool get tieneDni => dni.length == 8;
  bool get tieneNombre => nombres.isNotEmpty && apellidos.isNotEmpty;

  DatosDni unir(DatosDni o) => DatosDni(
        dni: o.dni.isNotEmpty ? o.dni : dni,
        apellidos: o.apellidos.isNotEmpty ? o.apellidos : apellidos,
        nombres: o.nombres.isNotEmpty ? o.nombres : nombres,
        domicilio: o.domicilio.isNotEmpty ? o.domicilio : domicilio,
      );
}

String _limpiaNombre(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'[^A-ZÁÉÍÓÚÑÜ ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

bool _esNombre(String s) {
  final l = _limpiaNombre(s);
  return l.length >= 2 && !RegExp(r'APELLIDO|NOMBRE|DNI|REPUBLICA|REPÚBLICA|PERU|PERÚ|FECHA|SEXO|NACIMIENTO|ESTADO|CIVIL|DOMICILIO').hasMatch(l);
}

/// Número de DNI (8 dígitos): primero la zona de lectura automática (I<PER12345678), luego "DNI 12345678", luego cualquier número de 8 dígitos suelto.
String? extraerDni(String texto) {
  final t = texto.toUpperCase();
  final mrz = RegExp(r'I\s*[<«]\s*PER\s*(\d{8})').firstMatch(t);
  if (mrz != null) return mrz.group(1);
  final conEtiqueta = RegExp(r'DNI\D{0,6}(\d{8})(?!\d)').firstMatch(t);
  if (conEtiqueta != null) return conEtiqueta.group(1);
  for (final l in t.split(RegExp(r'[\r\n]+'))) {
    if (l.contains('<')) continue; // líneas de la zona automática: traen fechas de 6 dígitos y otros números
    final m = RegExp(r'(?<!\d)(\d{8})(?!\d)').firstMatch(l);
    if (m != null) return m.group(1);
  }
  return null;
}

/// Apellidos y nombres, por las etiquetas del frente ("Primer Apellido", "Segundo Apellido", "Pre Nombres")
/// o, si no, por la zona automática del reverso (APELLIDO1<APELLIDO2<<NOMBRE1<NOMBRE2).
DatosDni extraerNombres(String texto) {
  final lineas = texto.split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  String valorDe(RegExp etiqueta) {
    for (var i = 0; i < lineas.length; i++) {
      final l = lineas[i];
      final m = etiqueta.firstMatch(l);
      if (m == null) continue;
      final resto = l.substring(m.end).trim();
      if (_esNombre(resto)) return _limpiaNombre(resto);
      for (var j = i + 1; j < lineas.length && j <= i + 2; j++) {
        if (_esNombre(lineas[j]) && !RegExp(r'\d').hasMatch(lineas[j])) return _limpiaNombre(lineas[j]);
      }
    }
    return '';
  }

  final ap1 = valorDe(RegExp(r'primer\s+apellido', caseSensitive: false));
  final ap2 = valorDe(RegExp(r'segundo\s+apellido', caseSensitive: false));
  final nom = valorDe(RegExp(r'pre\s*nombres?|nombres?', caseSensitive: false));
  if (nom.isNotEmpty && (ap1.isNotEmpty || ap2.isNotEmpty)) {
    return DatosDni(apellidos: [ap1, ap2].where((e) => e.isNotEmpty).join(' '), nombres: nom);
  }

  for (final l in lineas) {
    final u = l.toUpperCase().replaceAll(' ', '');
    if (!u.contains('<<') || RegExp(r'\d').hasMatch(u)) continue;
    final partes = u.split('<<').where((e) => e.replaceAll('<', '').isNotEmpty).toList();
    if (partes.length < 2) continue;
    final apellidos = _limpiaNombre(partes[0].replaceAll('<', ' '));
    final nombres = _limpiaNombre(partes.sublist(1).join(' ').replaceAll('<', ' '));
    if (apellidos.isNotEmpty && nombres.isNotEmpty) return DatosDni(apellidos: apellidos, nombres: nombres);
  }
  return const DatosDni();
}

/// Una línea de texto con su posición en la imagen (para saber qué valor está debajo de qué etiqueta).
class LineaGeo {
  const LineaGeo(this.texto, this.izq, this.arriba, this.ancho, this.alto);
  final String texto;
  final double izq;
  final double arriba;
  final double ancho;
  final double alto;
}

/// Apellidos y nombres usando la posición: el valor de "Primer Apellido", "Segundo Apellido" y "Pre Nombres"
/// es el texto que está justo debajo de su etiqueta (o a su lado). No depende del orden en que la cámara entregue las líneas.
DatosDni extraerNombresGeo(List<LineaGeo> lineas) {
  final etiquetas = <String, RegExp>{
    'ap1': RegExp(r'PRIMER\s+APELLIDO'),
    'ap2': RegExp(r'SEGUNDO\s+APELLIDO'),
    'nom': RegExp(r'PRE\s*NOMBRES?'),
  };
  bool esEtiqueta(LineaGeo l) => etiquetas.values.any((r) => r.hasMatch(l.texto.toUpperCase()));

  String valor(RegExp et) {
    for (final l in lineas) {
      final u = l.texto.toUpperCase();
      final m = et.firstMatch(u);
      if (m == null) continue;
      final resto = l.texto.substring(m.end).trim();
      if (_esNombre(resto) && !RegExp(r'\d').hasMatch(resto)) return _limpiaNombre(resto);
      LineaGeo? mejor;
      var mejorDist = double.infinity;
      for (final c in lineas) {
        if (identical(c, l) || esEtiqueta(c)) continue;
        if (RegExp(r'\d').hasMatch(c.texto) || !_esNombre(c.texto)) continue;
        final dy = c.arriba - l.arriba;
        if (dy < l.alto * 0.4 || dy > l.alto * 5) continue;
        final dx = (c.izq - l.izq).abs();
        if (dx > (l.ancho * 0.6 < 40 ? 40 : l.ancho * 0.6)) continue;
        if (dy < mejorDist) {
          mejorDist = dy;
          mejor = c;
        }
      }
      if (mejor != null) return _limpiaNombre(mejor.texto);
    }
    return '';
  }

  final ap1 = valor(etiquetas['ap1']!);
  final ap2 = valor(etiquetas['ap2']!);
  final nom = valor(etiquetas['nom']!);
  if (nom.isEmpty || (ap1.isEmpty && ap2.isEmpty)) return const DatosDni();
  return DatosDni(apellidos: [ap1, ap2].where((e) => e.isNotEmpty).join(' '), nombres: nom);
}

/// Qué lado del DNI es el texto. Frente: foto, apellidos, nombres, nacimiento y las líneas automáticas (I<PER...<<).
/// Reverso: dirección, distrito, provincia, departamento, grupo sanguíneo, donación de órganos, constancia de sufragio.
/// Gana el lado con más señales; null si no se sabe.
String? ladoDelDni(String texto) {
  final t = texto.toUpperCase();
  var rev = 0, fre = 0;
  if (t.contains('<<') || RegExp(r'I\s*[<«]\s*PER').hasMatch(t)) fre += 3;
  for (final m in [
    'DOMICILIO', 'DIRECCI', 'DISTRITO', 'PROVINCIA', 'DEPARTAMENTO', 'DONACI', 'RESTRICCI', 'EMISI', 'CADUC',
    'SUFRAGIO', 'SANGUIN', 'OBSERVACIONES', 'VOTACI',
  ]) {
    if (t.contains(m)) rev++;
  }
  for (final m in [
    RegExp(r'PRIMER\s+APELLIDO'),
    RegExp(r'SEGUNDO\s+APELLIDO'),
    RegExp(r'PRE\s*NOMBRES'),
    RegExp(r'NACIMIENTO'),
    RegExp(r'ESTADO\s+CIVIL'),
    RegExp(r'GRADO\s+DE\s+INSTRUCCI'),
    RegExp(r'DNI\D{0,6}\d{8}'),
  ]) {
    if (m.hasMatch(t)) fre++;
  }
  if (rev >= 2 && rev > fre) return 'reverso';
  if (fre >= 2 && fre > rev) return 'frente';
  return null;
}

final _etiqueta = RegExp(r'^(DIRECCI[OÓ]N|DOMICILIO|DISTRITO|PROVINCIA|DEPARTAMENTO)\b');
final _ruido = RegExp(
    r'CONSTANCIA|SUFRAGIO|GRUPO|FACTOR|SANGU|VOTACI|CUARTO|NIVEL|OBSERVACIONES|DONACI|RESTRICCI|EMISI|CADUC|FECHA|^DE$|^SI$|^NO$|<');

bool _dato(String l, {bool permiteNumeros = false}) {
  final u = l.trim().toUpperCase();
  if (u.length < 2 || _etiqueta.hasMatch(u) || _ruido.hasMatch(u)) return false;
  if (!permiteNumeros && RegExp(r'\d').hasMatch(u)) return false;
  if (RegExp(r'^[\d\s/\-.]+$').hasMatch(u)) return false;
  return true;
}

/// Partes del domicilio del reverso: dir, distrito, provincia, departamento.
/// El valor puede ir junto a la etiqueta, en la línea de abajo o (según como lea la cámara) en la de arriba.
Map<String, String> partesDomicilio(String texto) {
  final lineas = texto.split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final usadas = <int>{};
  final out = <String, String>{};

  String buscar(String clave, RegExp et, {bool numeros = false, bool atras = true}) {
    for (var i = 0; i < lineas.length; i++) {
      final u = lineas[i].toUpperCase();
      final m = et.firstMatch(u);
      if (m == null) continue;
      final resto = lineas[i].substring(m.end).replaceAll(RegExp(r'^[\s:.\-]+'), '').trim();
      if (resto.length >= 2 && _dato(resto, permiteNumeros: numeros)) return resto.toUpperCase();
      if (i + 1 < lineas.length && !usadas.contains(i + 1) && _dato(lineas[i + 1], permiteNumeros: numeros)) {
        usadas.add(i + 1);
        return lineas[i + 1].toUpperCase();
      }
      if (atras && i > 0 && !usadas.contains(i - 1) && _dato(lineas[i - 1], permiteNumeros: numeros)) {
        usadas.add(i - 1);
        return lineas[i - 1].toUpperCase();
      }
    }
    return '';
  }

  out['dir'] = buscar('dir', RegExp(r'DIRECCI[OÓ]N|DOMICILIO'), numeros: true, atras: false);
  out['departamento'] = buscar('departamento', RegExp(r'DEPARTAMENTO'));
  out['provincia'] = buscar('provincia', RegExp(r'PROVINCIA'));
  out['distrito'] = buscar('distrito', RegExp(r'DISTRITO'));
  return out;
}

String _unirDomicilio(Map<String, String> p) =>
    [p['dir'], p['distrito'], p['provincia'], p['departamento']].where((e) => e != null && e.isNotEmpty).join(', ');

/// Domicilio del reverso: dirección, distrito, provincia y departamento. Vacío si no hay dirección.
String extraerDomicilio(String texto) {
  final p = partesDomicilio(texto);
  if ((p['dir'] ?? '').isEmpty) return '';
  return _unirDomicilio(p);
}

/// Lee todo lo que se pueda de un texto.
DatosDni leerDni(String texto, [List<LineaGeo>? lineas]) {
  final geo = lineas == null ? const DatosDni() : extraerNombresGeo(lineas);
  final n = geo.tieneNombre ? geo : extraerNombres(texto);
  return DatosDni(dni: extraerDni(texto) ?? '', apellidos: n.apellidos, nombres: n.nombres, domicilio: extraerDomicilio(texto));
}

/// Acumula lecturas de varios cuadros: un DNI se da por bueno cuando se ve igual en [minimo] cuadros.
class AcumuladorDni {
  AcumuladorDni({this.minimo = 2});
  final int minimo;
  final Map<String, int> _dnis = {};
  final Map<String, int> _nombres = {};
  final Map<String, DatosDni> _porNombre = {};
  final Map<String, Map<String, int>> _partes = {};

  void anotar(String texto, [List<LineaGeo>? lineas]) {
    final d = leerDni(texto, lineas);
    if (d.dni.isNotEmpty) _dnis[d.dni] = (_dnis[d.dni] ?? 0) + 1;
    partesDomicilio(texto).forEach((k, v) {
      if (v.isEmpty) return;
      final m = _partes.putIfAbsent(k, () => {});
      m[v] = (m[v] ?? 0) + 1;
    });
    if (d.tieneNombre) {
      final k = '${d.apellidos}|${d.nombres}';
      _nombres[k] = (_nombres[k] ?? 0) + 1;
      _porNombre[k] = d;
    }
  }

  String? get dni {
    String? mejor;
    var n = 0;
    _dnis.forEach((k, v) {
      if (v >= minimo && v > n) {
        mejor = k;
        n = v;
      }
    });
    return mejor;
  }

  DatosDni? get nombre {
    String? mejor;
    var n = 0;
    _nombres.forEach((k, v) {
      if (v >= minimo && v > n) {
        mejor = k;
        n = v;
      }
    });
    return mejor == null ? null : _porNombre[mejor];
  }

  /// El valor más visto de cada parte (basta una lectura: se puede corregir a mano).
  String get domicilio {
    final p = <String, String>{};
    _partes.forEach((k, m) {
      String mejor = '';
      var n = 0;
      m.forEach((v, c) {
        if (c > n) {
          mejor = v;
          n = c;
        }
      });
      p[k] = mejor;
    });
    if ((p['dir'] ?? '').isEmpty) return '';
    return _unirDomicilio(p);
  }

  DatosDni get datos => (nombre ?? const DatosDni()).unir(DatosDni(dni: dni ?? '', domicilio: domicilio));
}
