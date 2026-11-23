import 'package:casa_empenio_pe/presentation/app/utils/dni_logica.dart' show LineaGeo;
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

  test('modelo con nombre: laptop Lenovo IdeaPad', () {
    final v = <String, int>{};
    for (var i = 0; i < 3; i++) {
      anotarCuadro('modelo', 'Lenovo\nIdeaPad Slim 3\n15IAH8\nIntel Core i5\nMade in China', v);
    }
    final p = proponerCampo('modelo', v)!;
    expect(p.startsWith('IDEAPAD SLIM 3'), isTrue);
    expect(puntosDeCandidato('modelo', 'INTEL CORE I5'), 0);
    expect(puntosDeCandidato('modelo', 'MADE IN CHINA'), 0);
    expect(puntosDeCandidato('modelo', 'LENOVO'), 0);
  });

  test('modelo con nombre: celular Samsung Galaxy S24', () {
    final v = <String, int>{};
    for (var i = 0; i < 3; i++) {
      anotarCuadro('modelo', 'SAMSUNG\nGalaxy S24\nMade in Vietnam', v);
    }
    expect(proponerCampo('modelo', v), contains('GALAXY S24'));
  });

  test('modelo: sigue tomando codigos y la etiqueta con nombre', () {
    expect(puntosDeCandidato('modelo', 'SM-A155M/DSN'), greaterThan(0));
    expect(valorTrasEtiqueta('modelo', 'Model Name: IdeaPad Slim 3 15IAH8'), 'IDEAPAD SLIM 3 15IAH8');
  });

  test('la descripcion no se llena de grupos de palabras', () {
    expect(candidatosDeTexto('LAPTOP HP 15 PULGADAS').length, lessThan(6));
  });

  test('elegir con el dedo: recuadro y toque', () {
    final l = [
      const LineaGeo('IdeaPad', 100, 200, 200, 40),
      const LineaGeo('Slim 3', 320, 205, 150, 40),
      const LineaGeo('Intel Core i5', 100, 400, 300, 40),
      const LineaGeo('S/N PF3ABCD1', 100, 600, 300, 40),
    ];
    expect(textoDeArea(l, 80, 180, 500, 260), 'IDEAPAD SLIM 3');
    expect(textoDeArea(l, 80, 380, 500, 460), 'INTEL CORE I5');
    expect(textoDeArea(l, 0, 0, 50, 50), '');
    expect(textoDeToque(l, 150, 215), 'IDEAPAD');
    expect(textoDeToque(l, 700, 900), '');
  });
}
