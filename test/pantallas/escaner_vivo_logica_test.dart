import 'package:casa_empenio_pe/presentation/app/utils/escaner_vivo_logica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no propone con una sola lectura suelta', () {
    final v = <String, int>{};
    anotarCuadro('serie', 'SERIAL NO R58M30XYZAB', v);
    // una sola vez: la etiqueta pesa 3, pero el resto del texto no
    expect(proponerCampo('serie', {'R58M30XYZAB': 1}), isNull);
  });

  test('serie: la etiqueta S/N gana y se estabiliza con varios cuadros', () {
    final v = <String, int>{};
    for (var i = 0; i < 3; i++) {
      anotarCuadro('serie', 'Galaxy A15\nS/N: R58M30XYZAB\nMADE IN VIETNAM', v);
    }
    expect(proponerCampo('serie', v), 'R58M30XYZAB');
  });

  test('placa: reconoce formato peruano', () {
    final v = <String, int>{'8418-GU': 3, 'TOYOTA': 3, 'ABC123X9': 3};
    expect(proponerCampo('placa', v), '8418-GU');
    expect(proponerCampo('placa', {'ABC-123': 2}), 'ABC-123');
    expect(proponerCampo('placa', {'TOYOTA': 5}), isNull);
  });

  test('modelo: toma el valor tras MODEL y no la palabra MODEL', () {
    final v = <String, int>{};
    for (var i = 0; i < 2; i++) {
      anotarCuadro('modelo', 'MODEL: SM-A155M/DSN\nFCC ID', v);
    }
    expect(proponerCampo('modelo', v), 'SM-A155M/DSN');
  });

  test('descripcion: propone una línea legible repetida', () {
    final v = <String, int>{'LAPTOP HP 15': 3, 'HP': 3};
    expect(proponerCampo('descripcion', v), 'LAPTOP HP 15');
  });

  test('candidatos ignora basura muy corta o larga', () {
    final c = candidatosDeTexto('ab\nSERIE 123456789\n${'x' * 80}');
    expect(c.contains('123456789'), isTrue);
    expect(c.any((e) => e.length > 40), isFalse);
  });
}
