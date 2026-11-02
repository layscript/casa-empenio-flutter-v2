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

w.Widget _firmas(String izq, String der, {Uint8List? firmaDer}) => w.Padding(
      padding: const w.EdgeInsets.only(top: 60),
      child: w.Row(
        mainAxisAlignment: w.MainAxisAlignment.spaceAround,
        children: [
          for (final t in [izq, der])
            w.Column(children: [
              if (t == der && firmaDer != null)
                w.Image(w.MemoryImage(firmaDer), width: 150, height: 55, fit: w.BoxFit.contain),
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
Future<Uint8List> pdfContrato(Map<String, dynamic> t, Map<String, dynamic> c, {Uint8List? firma}) async {
  final doc = w.Document();
  final tipo = (c['tipo'] ?? 'INDEFINIDO').toString();
  final cargo = (c['cargo'] ?? t['cargo'] ?? 'trabajador').toString();
  final rem = (c['remuneracion'] as num?) ?? 0;
  final inicio = _fechaLarga(c['fechaInicio']?.toString());
  final fin = c['fechaFin'] == null ? null : _fechaLarga(c['fechaFin'].toString());
  final jornada = ((c['jornada'] ?? '').toString().trim().isEmpty)
      ? 'de lunes a sábado, dentro de la jornada máxima legal de 8 horas diarias o 48 horas semanales, en el horario que fije EL EMPLEADOR'
      : c['jornada'].toString().trim();
  final funciones = ((c['funciones'] ?? '').toString().trim().isEmpty)
      ? 'las funciones propias del puesto y las que se le encomienden razonablemente'
      : c['funciones'].toString().trim();
  final lugar = ((c['lugar'] ?? '').toString().trim().isEmpty) ? _domicilio : c['lugar'].toString().trim();
  final mype = (t['regimen'] ?? '') != 'GENERAL';
  final locacion = tipo == 'LOCACION';
  final pension = t['pension'] == 'AFP' ? 'al Sistema Privado de Pensiones (AFP ${t['afp'] ?? ''})' : t['pension'] == 'ONP' ? 'al Sistema Nacional de Pensiones (ONP)' : 'a un sistema de pensiones (ONP o AFP) a su elección';

  String titulo;
  switch (tipo) {
    case 'PLAZO_FIJO':
      titulo = 'CONTRATO DE TRABAJO SUJETO A MODALIDAD (A PLAZO FIJO)';
      break;
    case 'POR_DIAS':
      titulo = 'CONTRATO DE TRABAJO POR DÍAS (EVENTUAL)';
      break;
    case 'LOCACION':
      titulo = 'CONTRATO DE LOCACIÓN DE SERVICIOS (RECIBO POR HONORARIOS)';
      break;
    default:
      titulo = 'CONTRATO DE TRABAJO A PLAZO INDETERMINADO';
  }
  final pagoTxt = tipo == 'POR_DIAS'
      ? 'un pago de ${_s(rem)} por cada día efectivamente trabajado, que se cancela al término de cada jornada o en la fecha que acuerden las partes'
      : locacion
          ? 'una retribución mensual de ${_s(rem)}, que se pagará contra la entrega del recibo por honorarios electrónico correspondiente'
          : 'una remuneración mensual de ${_s(rem)}, que se pagará por periodos vencidos, sujeta a los descuentos y aportes de ley';

  final partes = 'Conste por el presente documento el ${locacion ? 'contrato de locación de servicios' : 'contrato de trabajo'} que celebran, de una parte, $_empresa, con RUC N° $_ruc y domicilio en $_domicilio, a quien en adelante se le denominará ${locacion ? 'EL COMITENTE' : 'EL EMPLEADOR'}; y de la otra parte, don(ña) ${_nombre(t)}, identificado(a) con DNI N° ${t['dni'] ?? '__________'}${(t['domicilio'] ?? '').toString().isNotEmpty ? ', con domicilio en ${t['domicilio']}' : ''}, a quien en adelante se le denominará ${locacion ? 'EL LOCADOR' : 'EL TRABAJADOR'}, en los términos y condiciones siguientes:';

  final cl = <List<String>>[];
  if (locacion) {
    cl.addAll([
      ['PRIMERA: ANTECEDENTES', '$_empresa es una empresa dedicada a las actividades de préstamos con garantía prendaria, compra y venta de bienes, y servicios afines, y requiere contar con servicios independientes en el área de $cargo.'],
      ['SEGUNDA: OBJETO', 'EL LOCADOR se obliga a prestar de manera independiente y sin subordinación el siguiente servicio: $funciones. Lo ejecutará con sus propios medios y organización, y entregará los resultados acordados.'],
      ['TERCERA: PLAZO', 'El servicio se prestará desde el $inicio${fin != null ? ' hasta el $fin' : ' por tiempo indeterminado, pudiendo cualquiera de las partes ponerle término con aviso previo escrito de siete (7) días'}.'],
      ['CUARTA: RETRIBUCIÓN', 'EL COMITENTE pagará a EL LOCADOR $pagoTxt. EL LOCADOR declara contar con RUC activo y se obliga a emitir su recibo por honorarios; si correspondiera retención de impuesto a la renta de cuarta categoría, EL COMITENTE la efectuará conforme a ley.'],
      ['QUINTA: INDEPENDENCIA', 'Las partes declaran que este contrato es de naturaleza civil y no genera vínculo laboral. EL LOCADOR no está sujeto a horario ni a subordinación, no recibe beneficios laborales y es responsable de sus propios aportes y de su seguro de salud.'],
      ['SEXTA: CONFIDENCIALIDAD', 'EL LOCADOR se obliga a guardar reserva sobre la información de clientes, prendas en garantía, caja y operaciones de la empresa, durante y después del contrato.'],
      ['SÉPTIMA: RESOLUCIÓN', 'Cualquiera de las partes puede resolver el contrato por incumplimiento de la otra, previa comunicación escrita, sin perjuicio de pagar los servicios ya prestados.'],
    ]);
  } else {
    cl.addAll([
      ['PRIMERA: ANTECEDENTES', '$_empresa es una empresa dedicada a las actividades de préstamos con garantía prendaria, compra y venta de bienes, y servicios afines, y requiere contratar personal para el cargo de $cargo.'],
      ['SEGUNDA: OBJETO Y FUNCIONES', 'EL EMPLEADOR contrata los servicios personales de EL TRABAJADOR para desempeñar el cargo de $cargo, con las siguientes funciones: $funciones, además de las que se le encomienden razonablemente en relación a su puesto.'],
      [
        'TERCERA: PLAZO',
        tipo == 'PLAZO_FIJO'
            ? 'El presente contrato es sujeto a modalidad, por necesidad de mercado o incremento de actividad, y rige desde el $inicio hasta el ${fin ?? '__________'}. Podrá renovarse por acuerdo escrito de las partes dentro de los límites de ley. Vencido el plazo, el contrato termina sin necesidad de aviso.'
            : tipo == 'POR_DIAS'
                ? 'La prestación es eventual y por días. EL TRABAJADOR acudirá cuando sea convocado y se pagará solo por los días efectivamente laborados, a partir del $inicio. No genera obligación de continuidad para ninguna de las partes.'
                : 'El presente contrato es a plazo indeterminado y rige desde el $inicio. Las partes acuerdan un periodo de prueba de tres (3) meses, conforme a ley.'
      ],
      ['CUARTA: REMUNERACIÓN', 'EL EMPLEADOR pagará a EL TRABAJADOR $pagoTxt.'],
      ['QUINTA: JORNADA Y HORARIO', 'EL TRABAJADOR prestará servicios $jornada. Debe registrar su asistencia (entrada y salida) con el sistema que la empresa disponga, incluida la fotografía de control. El tiempo de refrigerio no forma parte de la jornada. El trabajo en sobretiempo es voluntario, debe ser autorizado y se paga con los recargos de ley.'],
      ['SEXTA: DESCANSOS', tipo == 'POR_DIAS' ? 'Por la naturaleza eventual del servicio, se pagan los días trabajados.' : 'EL TRABAJADOR gozará de un descanso semanal obligatorio, de los feriados no laborables y de las vacaciones que correspondan por ley. Si labora en feriado o en su día de descanso sin descanso sustitutorio, se le pagará la sobretasa de ley.'],
      [
        'SÉPTIMA: BENEFICIOS Y SEGURIDAD SOCIAL',
        tipo == 'POR_DIAS'
            ? 'Los beneficios que correspondan por ley se otorgarán según el régimen aplicable. EL TRABAJADOR queda afiliado $pension.'
            : mype
                ? 'EL TRABAJADOR se encuentra bajo el régimen laboral especial de la micro y pequeña empresa y gozará de los derechos y beneficios que ese régimen establece. Será afiliado $pension y registrado en planilla electrónica y en EsSalud, según corresponda.'
                : 'EL TRABAJADOR gozará de los beneficios del régimen laboral general: gratificaciones de julio y diciembre, CTS, vacaciones, asignación familiar cuando corresponda. Será afiliado $pension y registrado en planilla electrónica y en EsSalud.'
      ],
      ['OCTAVA: OBLIGACIONES', 'EL TRABAJADOR se obliga a guardar absoluta reserva sobre la información de clientes, prendas en garantía, caja y operaciones de la empresa; a cuidar los bienes y el dinero que se le confíen; a rendir cuentas del dinero que maneje; a cumplir las normas de seguridad y salud en el trabajo y el reglamento de la empresa.'],
      ['NOVENA: DESCUENTOS', 'EL TRABAJADOR autoriza que se descuenten de su remuneración los aportes de ley, los adelantos o préstamos recibidos de EL EMPLEADOR (que constarán por escrito, firma o registro fotográfico del recibo) y, previa comprobación, los faltantes o daños que le sean imputables, dentro de los límites legales.'],
      ['DÉCIMA: TERMINACIÓN', 'El contrato termina por las causas previstas en la ley (mutuo acuerdo, renuncia, vencimiento del plazo, falta grave u otras). Si EL TRABAJADOR decide renunciar, comunicará su decisión por escrito con treinta (30) días de anticipación, salvo exoneración del empleador.'],
    ]);
  }
  cl.add([
    locacion ? 'OCTAVA: DOMICILIO Y JURISDICCIÓN' : 'UNDÉCIMA: DOMICILIO Y JURISDICCIÓN',
    'El lugar de prestación del servicio es: $lugar. Las partes fijan como domicilios los indicados en este documento. Para todo lo no previsto se aplican las normas legales vigentes y las partes se someten a los jueces y tribunales de la jurisdicción de Atalaya, Ucayali.',
  ]);

  doc.addPage(w.MultiPage(
    pageFormat: p.PdfPageFormat.a4,
    margin: const w.EdgeInsets.fromLTRB(46, 40, 46, 40),
    build: (ctx) => [
      _titulo(titulo),
      _parrafo(partes),
      for (final k in cl) ...[
        w.Text(k[0], style: w.TextStyle(fontSize: 10.5, fontWeight: w.FontWeight.bold)),
        w.SizedBox(height: 3),
        _parrafo(k[1]),
      ],
      _parrafo('En señal de conformidad, las partes firman en dos ejemplares en la ciudad de Atalaya, a los ${_fechaLarga(c['fechaInicio']?.toString())}.'),
      _firmas(locacion ? 'EL COMITENTE\n$_empresa' : 'EL EMPLEADOR\n$_empresa', '${locacion ? 'EL LOCADOR' : 'EL TRABAJADOR'}\n${_nombre(t)}\nDNI ${t['dni'] ?? ''}', firmaDer: firma),
      if (firma != null) w.Text('Firmado digitalmente el ${_fechaLarga(c['firmadoAt']?.toString())}', style: const w.TextStyle(fontSize: 8)),
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


// ===========================================================================
// Recibo de entrega (adelanto, pago de jornal, sueldo, etc.)
// ===========================================================================
Future<Uint8List> pdfRecibo(Map<String, dynamic> pago, Map<String, dynamic> t, {Uint8List? foto, Uint8List? firma}) async {
  final doc = w.Document();
  final tipos = {
    'ADELANTO': 'ADELANTO DE SUELDO', 'PRESTAMO': 'PRÉSTAMO', 'QUINCENA': 'PAGO DE QUINCENA', 'SUELDO': 'PAGO DE SUELDO', 'JORNAL': 'PAGO DE JORNAL (DÍAS TRABAJADOS)',
    'GRATIFICACION': 'GRATIFICACIÓN', 'CTS': 'CTS', 'VACACIONES': 'VACACIONES', 'LIQUIDACION': 'LIQUIDACIÓN DE BENEFICIOS SOCIALES',
  };
  final monto = (pago['monto'] as num?) ?? 0;
  final f = DateTime.tryParse(pago['fecha']?.toString() ?? '')?.toLocal();
  final fecha = f == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(f);
  doc.addPage(w.Page(
    pageFormat: p.PdfPageFormat.a5,
    margin: const w.EdgeInsets.all(30),
    build: (ctx) => w.Column(crossAxisAlignment: w.CrossAxisAlignment.start, children: [
      w.Text(_empresa, style: w.TextStyle(fontSize: 12, fontWeight: w.FontWeight.bold)),
      w.Text('RUC $_ruc', style: const w.TextStyle(fontSize: 9)),
      _titulo('RECIBO DE ENTREGA N° ${pago['id']}'),
      _parrafo('Yo, ${_nombre(t)}, identificado(a) con DNI N° ${t['dni'] ?? ''}, declaro haber recibido de $_empresa la suma de ${_s(monto)} por concepto de ${tipos[pago['tipo']] ?? pago['tipo']}${pago['concepto'] != null ? ' (${pago['concepto']})' : ''}, en la fecha $fecha.'),
      if (pago['tipo'] == 'ADELANTO' || pago['tipo'] == 'PRESTAMO' || pago['tipo'] == 'QUINCENA')
        _parrafo('Autorizo que este monto sea descontado de mi remuneración o beneficios.'),
      w.SizedBox(height: 6),
      w.Row(crossAxisAlignment: w.CrossAxisAlignment.end, mainAxisAlignment: w.MainAxisAlignment.spaceBetween, children: [
        w.Column(children: [
          if (firma != null) w.Image(w.MemoryImage(firma), width: 150, height: 60, fit: w.BoxFit.contain) else w.SizedBox(height: 50),
          w.Container(width: 160, height: 1, color: p.PdfColors.black),
          w.Text('${_nombre(t)}\nDNI ${t['dni'] ?? ''}\n${firma != null ? 'Firma digital' : 'Firma'}', textAlign: w.TextAlign.center, style: const w.TextStyle(fontSize: 8)),
        ]),
        if (foto != null) w.Image(w.MemoryImage(foto), width: 110, height: 110, fit: w.BoxFit.cover),
      ]),
      w.SizedBox(height: 8),
      w.Text('Entregado por: ${pago['usuarioNombre'] ?? ''}', style: const w.TextStyle(fontSize: 8)),
    ]),
  ));
  return doc.save();
}
