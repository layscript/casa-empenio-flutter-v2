import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Si una llamada al servidor escribe la ruta sin la barra inicial ('operacion/...' en vez de '/operacion/...'),
/// la dirección queda pegada al puerto ("...:3000operacion/...") y falla con «Invalid port».
void main() {
  test('Todas las rutas relativas al servidor empiezan con /', () {
    final patron = RegExp(r"""\.(get|post|put|patch|delete)(<[A-Za-z<>?, ]+>)?\(\s*['"]([a-zA-Z][^'"]*)['"]""");
    final malas = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final texto = f.readAsStringSync();
      for (final m in patron.allMatches(texto)) {
        final ruta = m.group(3)!;
        if (ruta.startsWith('http')) continue;
        malas.add('${f.path}: ${m.group(0)}');
      }
    }
    expect(malas, isEmpty, reason: 'Rutas sin "/" inicial:\n${malas.join('\n')}');
  });
}
