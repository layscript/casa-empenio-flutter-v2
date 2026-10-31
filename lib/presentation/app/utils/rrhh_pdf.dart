import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as w;
import 'package:printing/printing.dart';

// ---------------------------------------------------------------------------
// PDFs de Recursos Humanos: contrato de trabajo, carta de renuncia y boleta.
// Los textos son modelos de uso común; para casos especiales conviene que los
// revise el abogado o contador de la empresa.
// ---------------------------------------------------------------------------

const _empresa = 'NEGOCIOS MULTIPLES MAYTA E.I.R.L.';
const _ruc = '20611213221';
const _domicilio = 'CAL.URUBAMBA MZA. 8 LOTE. 8 UCAYALI - ATALAYA - RAYMONDI';

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre'
];

String _fechaLarga(String? iso) {
  if (iso == null || iso.length < 10) return '__________';
  final d = DateTime.tryParse(iso.substring(0, 10));
  if (d == null) return iso;
  return '${d.day} de ${_meses[d.month - 1]} de ${d.year}';
}

String _s(num? v) => 'S/ ${NumberFormat('#,##0.00').format(v ?? 0)}';

Future<void> mostrarPdf(Uint8List bytes, String nombre) async {
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: nombre);
}

w.Widget _titulo(String t) => w.Padding(
      padding: const w.EdgeInsets.only(top: 6, bottom: 12),
      child: w.Center(
        child: w.Text(t,
            textAlign: w.TextAlign.center,
            style: w.TextStyle(fontSize: 14, fontWeight: w.FontWeight.bold)),
      ),
    );

w.Widget _parrafo(String t) => w.Padding(
      padding: const w.EdgeInsets.only(bottom: 8),
      child: w.Text(t,
          textAlign: w.TextAlign.justify,
          style: const w.TextStyle(fontSize: 10.5, lineSpacing: 2)),
    );

w.Widget _firmas(String izq, String der) => w.Padding(
      padding: const w.EdgeInsets.only(top: 60),
      child: w.Row(
        mainAxisAlignment: w.MainAxisAlignment.spaceAround,
        children: [
          for (final t in [izq, der])
            w.Column(children: [
              w.Container(width: 180, height: 1, color: p.PdfColors.black),
              w.SizedBox(height: 4),
              w.Text(t, style: const w.TextStyle(fontSize: 10)),
            ]),
        ],
      ),
    );

String _nombre(Map t) => '${t['nombres'] ?? ''} ${t['apellidos'] ?? ''}'.trim().toUpperCase();

// ===========================================================================
// Contrato de trabajo
// ===========================================================================
Future<Uint8List> pdfContrato(Map<String, dynamic> t, Map<String, dynamic> c) async {
  final doc = w.Document();
  final tipo = (c['tipo'] ?? 'INDEFINIDO').toString();
  final cargo = (c['cargo'] ?? t['cargo'] ?? 'trabajador').toString();
  final rem = (c['remuneracion'] as num?) ?? 0;
  final inicio = _fechaLarga(c['fechaInicio']?.toString());
  final fin = c['fechaFin'] == null ? null : _fechaLarga(c['fechaFin'].toString());
  final jornada = (c['jornada'] ?? 'la jornada máxima legal, con el horario que fije el EMPLEADOR dentro de ella').toString();
  final mype = (t['regimen'] ?? '') != 'GENERAL' && tipo != 'LOCACION' && tipo != 'POR_DIAS';

  String titulo;
  switch (tipo) {
    case 'PLAZO_FIJO':
      titulo = 'CONTRATO DE TRABAJO SUJETO A MODALIDAD (A PLAZO FIJO)';
      break;
    case 'POR_DIAS':
      titulo = 'CONTRATO DE TRABAJO POR DÍAS (EVENTUAL)';
      break;
    case 'LOCACION':
      titulo = 'CONTRATO DE LOCACIÓN DE SERVICIOS';
      break;
    default:
      titulo = 'CONTRATO DE TRABAJO A PLAZO INDETERMINADO';
  }
  final sueldoTxt = tipo == 'POR_DIAS'
      ? 'un pago de ${_s(rem)} por cada día efectivamente trabajado, que se cancela al término de cada jornada o en la fecha que acuerden las partes'
      : tipo == 'LOCACION'
          ? 'una retribución mensual de ${_s(rem)}, contra la entrega del recibo por honorarios correspondiente'
          : 'una remuneración mensual de ${_s(rem)}, sujeta a los descuentos y aportes de ley';

  final partes = 'Conste por el presente documento el ${tipo == 'LOCACION' ? 'contrato de locación de servicios' : 'contrato de trabajo'} que celebran, de una parte, $_empresa, con RUC N° $_ruc y domicilio en $_domicilio, a quien en adelante se le denominará ${tipo == 'LOCACION' ? 'EL COMITENTE' : 'EL EMPLEADOR'}; y de la otra parte, don(ña) ${_nombre(t)}, identificado(a) con DNI N° ${t['dni'] ?? '__________'}${t['domicilio'] != null ? ', con domicilio en ${t['domicilio']}' : ''}, a quien en adelante se le denominará ${tipo == 'LOCACION' ? 'EL LOCADOR' : 'EL TRABAJADOR'}, en los términos y condiciones siguientes:';

  final clausulas = <List<String>>[];
  if (tipo == 'LOCACION') {
    clausulas.addAll([
      ['PRIMERA: OBJETO', 'EL LOCADOR se obliga a prestar de manera independiente, y sin subordinación, el servicio de $cargo a favor de EL COMITENTE, con sus propios medios y organización, y a entregar los resultados acordados.'],
      ['SEGUNDA: PLAZO', 'El servicio se prestará desde el $inicio${fin != null ? ' hasta el $fin' : ' por tiempo indefinido, pudiendo cualquiera de las partes ponerle término con aviso previo de 7 días'}.'],
      ['TERCERA: RETRIBUCIÓN', 'EL COMITENTE pagará a EL LOCADOR $sueldoTxt.'],
      ['CUARTA: INDEPENDENCIA', 'Las partes declaran que este contrato es de naturaleza civil y no genera vínculo laboral, por lo que EL LOCADOR no tiene derecho a beneficios laborales.'],
      ['QUINTA: CONFIDENCIALIDAD', 'EL LOCADOR se obliga a guardar reserva sobre la información de clientes, prendas, caja y operaciones de la empresa, durante y después del contrato.'],
    ]);
  } else {
    clausulas.addAll([
      ['PRIMERA: OBJETO', 'EL EMPLEADOR contrata los servicios personales de EL TRABAJADOR para desempeñar el cargo de $cargo, comprometiéndose este a cumplir con diligencia las funciones inherentes al puesto y las que se le encomienden razonablemente.'],
      [
        'SEGUNDA: PLAZO',
        tipo == 'PLAZO_FIJO'
            ? 'El presente contrato rige desde el $inicio hasta el ${fin ?? '__________'}, por necesidad del mercado / incremento de actividad, pudiendo renovarse por acuerdo escrito de las partes dentro de los límites de ley.'
            : tipo == 'POR_DIAS'
                ? 'La prestación es eventual y por días. EL TRABAJADOR irá cuando sea convocado y se pagará solo por los días efectivamente laborados, a partir del $inicio. No genera obligación de continuidad para ninguna de las partes.'
                : 'El presente contrato es a plazo indeterminado y rige desde el $inicio.'
      ],
      ['TERCERA: REMUNERACIÓN', 'EL EMPLEADOR pagará a EL TRABAJADOR $sueldoTxt.'],
      ['CUARTA: JORNADA Y HORARIO', 'EL TRABAJADOR cumplirá $jornada. Debe registrar su asistencia (entrada y salida) con el sistema que la empresa disponga, incluida la fotografía de control.'],
      [
        'QUINTA: BENEFICIOS',
        tipo == 'POR_DIAS'
            ? 'Por la naturaleza eventual del servicio, se pagan los días trabajados. Los beneficios que correspondan por ley se otorgarán según el régimen aplicable.'
            : mype
                ? 'EL TRABAJADOR se encuentra bajo el régimen laboral de la micro y pequeña empresa (Ley MYPE) y gozará de los derechos y beneficios que ese régimen establece, además de la afiliación a un sistema de pensiones (ONP o AFP) y a la seguridad social en salud.'
                : 'EL TRABAJADOR gozará de los beneficios del régimen laboral general: gratificaciones de julio y diciembre, CTS, vacaciones, asignación familiar cuando corresponda, y la afiliación a un sistema de pensiones y a EsSalud.'
      ],
      ['SEXTA: OBLIGACIONES', 'EL TRABAJADOR se obliga a guardar absoluta reserva sobre la información de clientes, prendas en garantía, caja y operaciones de la empresa; a cuidar los bienes que se le confíen, y a respetar el reglamento y las normas de seguridad. El incumplimiento grave será causal de término del contrato conforme a ley.'],
      ['SÉPTIMA: DESCUENTOS', 'EL TRABAJADOR autoriza que se descuenten de su remuneración los aportes de ley y los adelantos o préstamos que haya recibido de EL EMPLEADOR, los que constarán por escrito o con registro fotográfico del recibo.'],
    ]);
  }
  clausulas.add([
    tipo == 'LOCACION' ? 'SEXTA: JURISDICCIÓN' : 'OCTAVA: JURISDICCIÓN',
    'Para todo lo no previsto se aplican las normas legales vigentes. Las partes se someten a los jueces y tribunales de la jurisdicción de Atalaya, Ucayali.',
  ]);

  doc.addPage(w.MultiPage(
    pageFormat: p.PdfPageFormat.a4,
    margin: const w.EdgeInsets.fromLTRB(46, 40, 46, 40),
    build: (ctx) => [
      _titulo(titulo),
      _parrafo(partes),
      for (final c in clausulas) ...[
        w.Text(c[0], style: w.TextStyle(fontSize: 10.5, fontWeight: w.FontWeight.bold)),
        w.SizedBox(height: 3),
        _parrafo(c[1]),
      ],
      _parrafo('En señal de conformidad, las partes firman en dos ejemplares en la ciudad de Atalaya, a los ${_fechaLarga(c['fechaInicio']?.toString())}.'),
      _firmas(tipo == 'LOCACION' ? 'EL COMITENTE\n$_empresa' : 'EL EMPLEADOR\n$_empresa', '${tipo == 'LOCACION' ? 'EL LOCADOR' : 'EL TRABAJADOR'}\n${_nombre(t)}\nDNI ${t['dni'] ?? ''}'),
    ],
  ));
  return doc.save();
}

// ===========================================================================
// Carta de renuncia (para que el trabajador la firme)
// ===========================================================================
Future<Uint8List> pdfCartaRenuncia(Map<String, dynamic> t, String fecha, {String? ultimoDia}) async {
  final doc = w.Document();
  doc.addPage(w.Page(
    pageFormat: p.PdfPageFormat.a4,
    margin: const w.EdgeInsets.fromLTRB(60, 60, 60, 60),
    build: (ctx) => w.Column(crossAxisAlignment: w.CrossAxisAlignment.start, children: [
      w.Text('Atalaya, ${_fechaLarga(fecha)}', style: const w.TextStyle(fontSize: 11)),
      w.SizedBox(height: 28),
      w.Text('Señores', style: const w.TextStyle(fontSize: 11)),
      w.Text(_empresa, style: w.TextStyle(fontSize: 11, fontWeight: w.FontWeight.bold)),
      w.Text('Presente.-', style: const w.TextStyle(fontSize: 11)),
      w.SizedBox(height: 24),
      w.Text('Asunto: CARTA DE RENUNCIA VOLUNTARIA', style: w.TextStyle(fontSize: 11, fontWeight: w.FontWeight.bold)),
      w.SizedBox(height: 18),
      _parrafo('Yo, ${_nombre(t)}, identificado(a) con DNI N° ${t['dni'] ?? '__________'}, que vengo desempeñándome como ${t['cargo'] ?? 'trabajador'} en su representada desde el ${_fechaLarga(t['fechaIngreso']?.toString())}, me dirijo a ustedes para comunicarles mi decisión de RENUNCIAR de manera voluntaria e irrevocable al cargo que ocupo.'),
      _parrafo('Mi último día de labores será el ${_fechaLarga(ultimoDia ?? fecha)}. Agradezco la oportunidad brindada y me comprometo a entregar los bienes, llaves, documentos y cualquier información a mi cargo hasta esa fecha.'),
      _parrafo('Solicito que se me cancelen los beneficios sociales y remuneraciones pendientes que me correspondan por ley, y que se me entregue el certificado de trabajo.'),
      w.SizedBox(height: 10),
      _parrafo('Atentamente,'),
      _firmas('Firma', 'Huella digital'),
      w.SizedBox(height: 14),
      w.Text('${_nombre(t)}\nDNI ${t['dni'] ?? ''}', style: const w.TextStyle(fontSize: 10)),
    ]),
  ));
  return doc.save();
}

// ===========================================================================
// Boleta de pago / gratificación / CTS / liquidación
// ===========================================================================
Future<Uint8List> pdfBoleta(Map<String, dynamic> b, {String? nombre, String? dni}) async {
  final doc = w.Document();
  final det = (b['detalle'] is Map) ? Map<String, dynamic>.from(b['detalle'] as Map) : <String, dynamic>{};
  final tipo = (b['tipo'] ?? 'SUELDO').toString();
  final tNombre = nombre ?? (det['trabajador'] is Map ? _nombre(det['trabajador'] as Map) : det['trabajador']?.toString() ?? '');
  final tDni = dni ?? (det['trabajador'] is Map ? (det['trabajador'] as Map)['dni']?.toString() ?? '' : '');
  final ingresos = ((det['ingresos'] ?? det['items']) as List? ?? const []).cast<dynamic>();
  final descuentos = <Map>[
    ...((det['descuentosLista'] as List? ?? const []).cast<Map>()),
    if (det['descuentosLista'] == null && ((det['descuento'] as num?) ?? 0) > 0) {'concepto': 'Adelantos descontados', 'monto': det['descuento']},
  ];
  final aportes = (det['aportes'] as List? ?? const []).cast<Map>();
  final titulo = {
        'SUELDO': 'BOLETA DE PAGO',
        'GRATIFICACION': 'CONSTANCIA DE GRATIFICACIÓN',
        'CTS': 'CONSTANCIA DE CTS',
        'LIQUIDACION': 'LIQUIDACIÓN DE BENEFICIOS SOCIALES',
      }[tipo] ?? 'BOLETA DE PAGO';

  w.Widget fila(String a, num m, {bool negrita = false}) => w.Padding(
        padding: const w.EdgeInsets.symmetric(vertical: 2),
        child: w.Row(mainAxisAlignment: w.MainAxisAlignment.spaceBetween, children: [
          w.Expanded(child: w.Text(a, style: w.TextStyle(fontSize: 10.5, fontWeight: negrita ? w.FontWeight.bold : w.FontWeight.normal))),
          w.Text(_s(m), style: w.TextStyle(fontSize: 10.5, fontWeight: negrita ? w.FontWeight.bold : w.FontWeight.normal)),
        ]),
      );

  doc.addPage(w.MultiPage(
    pageFormat: p.PdfPageFormat.a4,
    margin: const w.EdgeInsets.fromLTRB(46, 40, 46, 40),
    build: (ctx) => [
      w.Text(_empresa, style: w.TextStyle(fontSize: 12, fontWeight: w.FontWeight.bold)),
      w.Text('RUC $_ruc\n$_domicilio', style: const w.TextStyle(fontSize: 9)),
      _titulo('$titulo - ${b['periodo'] ?? ''}'),
      w.Container(
        padding: const w.EdgeInsets.all(8),
        decoration: w.BoxDecoration(border: w.Border.all(color: p.PdfColors.grey600)),
        child: w.Column(crossAxisAlignment: w.CrossAxisAlignment.start, children: [
          w.Text('Trabajador: $tNombre', style: const w.TextStyle(fontSize: 10.5)),
          w.Text('DNI: $tDni', style: const w.TextStyle(fontSize: 10.5)),
          if (det['fecha'] != null) w.Text('Fecha de cese: ${_fechaLarga(det['fecha'].toString())}', style: const w.TextStyle(fontSize: 10.5)),
        ]),
      ),
      w.SizedBox(height: 10),
      w.Text('INGRESOS', style: w.TextStyle(fontSize: 11, fontWeight: w.FontWeight.bold)),
      w.Divider(),
      for (final i in ingresos) fila((i as Map)['concepto'].toString(), (i['monto'] as num?) ?? 0),
      fila('TOTAL INGRESOS', (b['bruto'] as num?) ?? 0, negrita: true),
      w.SizedBox(height: 10),
      w.Text('DESCUENTOS', style: w.TextStyle(fontSize: 11, fontWeight: w.FontWeight.bold)),
      w.Divider(),
      if (descuentos.isEmpty) w.Text('Sin descuentos', style: const w.TextStyle(fontSize: 10)),
      for (final d in descuentos) fila(d['concepto'].toString(), (d['monto'] as num?) ?? 0),
      fila('TOTAL DESCUENTOS', (b['descuentos'] as num?) ?? 0, negrita: true),
      w.SizedBox(height: 10),
      w.Container(
        padding: const w.EdgeInsets.all(8),
        color: p.PdfColors.grey200,
        child: fila('NETO A PAGAR', (b['neto'] as num?) ?? 0, negrita: true),
      ),
      if (aportes.isNotEmpty) ...[
        w.SizedBox(height: 10),
        w.Text('APORTES DEL EMPLEADOR (no se descuentan al trabajador)', style: w.TextStyle(fontSize: 10, fontWeight: w.FontWeight.bold)),
        for (final a in aportes) fila(a['concepto'].toString(), (a['monto'] as num?) ?? 0),
      ],
      _firmas('EMPLEADOR', 'TRABAJADOR\nRecibí conforme'),
    ],
  ));
  return doc.save();
}
