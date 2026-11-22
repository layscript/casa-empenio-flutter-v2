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

void pruebasLados() {
  test('Frente con estado civil no se confunde con el reverso', () {
    expect(ladoDelDni('DNI 46864068\nPrimer Apellido\nTORRE\nSegundo Apellido\nMAYTA\nPre Nombres\nJOEL MAYCO\nFecha de Nacimiento\nEstado Civil\nSOLTERO'), 'frente');
  });
  test('Reverso con etiquetas primero y valores despues', () {
    expect(extraerDomicilio('Domicilio\nDistrito\nProvincia\nDepartamento\nJR LIMA 123\nYARINACOCHA\nCORONEL PORTILLO\nUCAYALI'),
        'JR LIMA 123, YARINACOCHA, CORONEL PORTILLO, UCAYALI');
  });
  test('Lado del DNI', () {
    expect(ladoDelDni('DNI 45678912\nPrimer Apellido\nQUISPE'), 'frente');
    expect(ladoDelDni('DOMICILIO\nJR LIMA 123\nDISTRITO\nCALLERIA'), 'reverso');
    expect(ladoDelDni('I<PER45678912<3<<<\nQUISPE<<JUAN'), 'reverso');
    expect(ladoDelDni('hola'), isNull);
  });
  test('Domicilio del reverso', () {
    expect(extraerDomicilio('DOMICILIO\nJR LIMA 123\nDISTRITO\nCALLERIA\nPROVINCIA\nCORONEL PORTILLO\nDEPARTAMENTO\nUCAYALI'),
        'JR LIMA 123, CALLERIA, CORONEL PORTILLO, UCAYALI');
    expect(extraerDomicilio('Domicilio: AV ARAUJO 45\nDistrito: YARINACOCHA'), 'AV ARAUJO 45, YARINACOCHA');
    expect(extraerDomicilio('sin nada'), '');
  });
}
