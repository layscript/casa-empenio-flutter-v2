import 'package:casa_empenio_pe/presentation/app/utils/dni_logica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  pruebasLados();
  test('DNI con etiqueta', () {
    expect(extraerDni('REPUBLICA DEL PERU\nDNI 45678912 - 3\nPrimer Apellido'), '45678912');
  });
  test('DNI en zona automatica', () {
    expect(extraerDni('IDPER\nI<PER45678912<3<<<<<<<<<<<<<<<\n9001015M3001015PER<<<<<<<<<<<6'), '45678912');
  });
  test('DNI suelto, pero no fechas largas ni de la zona automatica', () {
    expect(extraerDni('Numero\n45678912'), '45678912');
    expect(extraerDni('123456789012'), isNull);
    expect(extraerDni('90010150<<M30010150'), isNull);
  });
  test('Nombres por etiquetas', () {
    final d = extraerNombres('Primer Apellido\nQUISPE\nSegundo Apellido\nMAMANI\nPre Nombres\nJUAN CARLOS\nFecha de nacimiento');
    expect(d.apellidos, 'QUISPE MAMANI');
    expect(d.nombres, 'JUAN CARLOS');
  });
  test('Nombres en la misma linea', () {
    final d = extraerNombres('Primer Apellido QUISPE\nSegundo Apellido MAMANI\nPre Nombres JUAN CARLOS');
    expect(d.apellidos, 'QUISPE MAMANI');
    expect(d.nombres, 'JUAN CARLOS');
  });
  test('Nombres por zona automatica', () {
    final d = extraerNombres('I<PER45678912<3<<<\n9001015M3001015PER<<<<<<<<<<<6\nQUISPE<MAMANI<<JUAN<CARLOS<<<<<<<<');
    expect(d.apellidos, 'QUISPE MAMANI');
    expect(d.nombres, 'JUAN CARLOS');
  });
  test('Acumulador pide ver el DNI en 2 cuadros', () {
    final a = AcumuladorDni();
    a.anotar('DNI 45678912');
    expect(a.dni, isNull);
    a.anotar('xx DNI 45678912 yy');
    expect(a.dni, '45678912');
    a.anotar('DNI 45678913');
    expect(a.dni, '45678912');
  });
  test('Etiquetas no se toman como nombre', () {
    final d = extraerNombres('Primer Apellido\nSegundo Apellido\nPre Nombres');
    expect(d.tieneNombre, false);
  });
}

void pruebasGeo() {
  test('Apellidos por posicion, aunque la camara entregue las lineas desordenadas', () {
    final l = [
      const LineaGeo('TORRE', 530, 1540, 160, 40),
      const LineaGeo('JOEL MAYCO', 525, 1700, 290, 40),
      const LineaGeo('Segundo Apellido', 530, 1500, 360, 40),
      const LineaGeo('Primer Apellido', 540, 1000, 300, 40),
      const LineaGeo('Pre Nombres', 530, 1660, 260, 40),
      const LineaGeo('MAYTA', 540, 1040, 140, 40),
      const LineaGeo('REPUBLICA DEL PERU', 60, 1190, 480, 40),
    ];
    final d = extraerNombresGeo(l);
    expect(d.apellidos, 'MAYTA TORRE');
    expect(d.nombres, 'JOEL MAYCO');
    expect(leerDni('DNI 46864068', l).apellidos, 'MAYTA TORRE');
  });
}

void pruebasLados() {
  pruebasGeo();
  test('Frente con estado civil no se confunde con el reverso', () {
    expect(ladoDelDni('DNI 46864068\nPrimer Apellido\nTORRE\nSegundo Apellido\nMAYTA\nPre Nombres\nJOEL MAYCO\nFecha de Nacimiento\nEstado Civil\nSOLTERO'), 'frente');
  });
  test('Reverso real (texto leido por la camara)', () {
    const txt = 'CONSTANCIA\nSUFRAGIO\nDE\nCONSTANCIA\ncONSTANCIA\nCONSTANCIA\nSUFRAGIO\nSUFRAGIO\nSUFRAGIO\nRAIMONDI\nDistrito\nProvincia\nATALAYA\nDepartamento\nUCAYALI\nDirección\nJR. PANGOA 319 MZ. 23\nGrupo y Factor Sanguineo\nGrupo de\nVotación 336279\nCuarto Nivel 250301\nObservaciones\nDonación de Organos SI';
    expect(ladoDelDni(txt), 'reverso');
    expect(extraerDomicilio(txt), 'JR. PANGOA 319 MZ. 23, RAIMONDI, ATALAYA, UCAYALI');
  });
  test('Frente con lineas automaticas es frente', () {
    const txt = 'REPUBLICA DEL PERU\nPrimer Apellido\nTORRE\nI<PER46864068<4<<<<<<<<<<<<<<<\n9203066M3304031PER<<<<<<<<<<<8\nMAYTA<<JOEL<MAYCO<<<<<<<<<<';
    expect(ladoDelDni(txt), 'frente');
  });
  test('Lado del DNI', () {
    expect(ladoDelDni('DNI 45678912\nPrimer Apellido\nQUISPE'), 'frente');
    expect(ladoDelDni('DOMICILIO\nJR LIMA 123\nDISTRITO\nCALLERIA'), 'reverso');
    expect(ladoDelDni('I<PER45678912<3<<<\nQUISPE<<JUAN\nPrimer Apellido'), 'frente');
    expect(ladoDelDni('hola'), isNull);
  });
  test('Domicilio del reverso', () {
    expect(extraerDomicilio('DOMICILIO\nJR LIMA 123\nDISTRITO\nCALLERIA\nPROVINCIA\nCORONEL PORTILLO\nDEPARTAMENTO\nUCAYALI'),
        'JR LIMA 123, CALLERIA, CORONEL PORTILLO, UCAYALI');
    expect(extraerDomicilio('Domicilio: AV ARAUJO 45\nDistrito: YARINACOCHA'), 'AV ARAUJO 45, YARINACOCHA');
    expect(extraerDomicilio('sin nada'), '');
  });
}
