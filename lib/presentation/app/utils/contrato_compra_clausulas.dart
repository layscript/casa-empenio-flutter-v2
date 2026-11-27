import 'package:casa_empenio_pe/presentation/app/utils/contrato_compraventa.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as w;

// ---------------------------------------------------------------------------
// Texto del CONTRATO PRIVADO DE COMPRA Y VENTA cuando la EMPRESA COMPRA a una
// persona (vehículo o artefacto de segundo uso) y de la DECLARACIÓN JURADA del
// vendedor. Redactado según el Código Civil peruano. Es un modelo base: conviene
// que un abogado lo revise una vez para el negocio.
// ---------------------------------------------------------------------------

const _ordinal = [
  'PRIMERA', 'SEGUNDA', 'TERCERA', 'CUARTA', 'QUINTA', 'SEXTA', 'SÉPTIMA', 'OCTAVA', 'NOVENA', 'DÉCIMA',
  'DÉCIMO PRIMERA', 'DÉCIMO SEGUNDA', 'DÉCIMO TERCERA', 'DÉCIMO CUARTA', 'DÉCIMO QUINTA', 'DÉCIMO SEXTA',
  'DÉCIMO SÉPTIMA', 'DÉCIMO OCTAVA', 'DÉCIMO NOVENA', 'VIGÉSIMA',
];

String _m(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

String _medioTexto(DatosContrato d) {
  final m = d.medioPago.trim();
  if (m.isEmpty || m.toUpperCase() == 'EFECTIVO') return 'en dinero en efectivo y en soles, en este acto';
  return 'en soles, en este acto, mediante $m a favor de EL VENDEDOR';
}

String _documentoTexto(DatosContrato d) {
  final doc = d.documentoPropiedad.trim();
  if (doc.isEmpty || doc.toLowerCase().startsWith('ninguno')) {
    return d.esVehiculo
        ? 'No presenta tarjeta de propiedad ni otro documento de adquisición; por ello declara bajo juramento su titularidad y autoriza a EL COMPRADOR a verificarla en SUNARP (Registro de Propiedad Vehicular) y ante las autoridades competentes, comparando serie, chasis y motor'
        : 'No presenta comprobante de compra; por ello declara bajo juramento su titularidad y autoriza a EL COMPRADOR a verificarla por los medios que considere necesarios';
  }
  return 'Acredita su propiedad con: $doc';
}

/// Cláusulas numeradas del contrato. [tabla] es la tabla de características del bien (se coloca tras la primera cláusula).
List<w.Widget> clausulasCompra(DatosContrato d, w.TextStyle base, w.TextStyle neg, {required w.Widget tabla}) {
  final bien = d.descripcion.trim().toUpperCase();
  final vendedor = 'EL VENDEDOR';
  final comprador = 'EL COMPRADOR';
  final veh = d.esVehiculo;
  final precio = 'S/. ${_m(d.precio)} (${precioEnLetras(d.precio)})';
  final casado = ['casado', 'casada', 'conviviente'].contains(d.estadoCivil.trim().toLowerCase());

  final items = <(String, String)>[
    (
      'OBJETO DEL CONTRATO',
      '$vendedor transfiere en venta definitiva y real a $comprador, y éste adquiere, el bien de SEGUNDO USO: $bien, cuyas características se detallan a continuación. '
          'El contrato se rige por las normas de la compraventa del Código Civil peruano (artículo 1529 y siguientes) y, en lo no previsto, por las demás normas aplicables.',
    ),
    (
      'PROPIEDAD Y LEGITIMIDAD',
      '$vendedor declara bajo juramento que es el único y legítimo propietario del bien, que lo adquirió de manera lícita y que tiene plena facultad para disponer de él. ${_documentoTexto(d)}. '
          'Declara también que no lo ha vendido, cedido ni ofrecido en venta a otra persona.',
    ),
    (
      'PRECIO Y FORMA DE PAGO',
      'El precio pactado es de $precio, que $comprador paga ${_medioTexto(d)}. $vendedor declara haberlo recibido a su entera satisfacción, por lo que el presente documento sirve de recibo y de cancelación total del precio. '
          'Nada se debe por ningún concepto adicional.',
    ),
    (
      'ENTREGA, TRADICIÓN Y RIESGOS',
      '$vendedor entrega en este acto la posesión del bien a $comprador, con ${veh ? 'sus llaves (original y duplicados), tarjeta de propiedad o documentos que posea y accesorios' : 'sus accesorios, cargador y demás componentes que se indican en las observaciones'}, '
          'operando la transferencia de propiedad por la tradición, de acuerdo con el Código Civil (artículo 947). Desde este momento el bien y sus riesgos pasan a ser de $comprador.',
    ),
    (
      'BIEN DE SEGUNDO USO Y ESTADO DEL BIEN',
      '$vendedor declara que el bien es de SEGUNDO USO y que ha informado a $comprador su estado real de funcionamiento, desgaste y reparaciones, que consta en la descripción y observaciones'
          '${d.estado.trim().isEmpty ? '' : ' (${d.estado.trim()})'}. '
          '$comprador lo adquiere en el estado en que se encuentra. $vendedor responde por los defectos ocultos que conociera y no hubiera informado.',
    ),
    (
      'BIEN LIBRE DE CARGAS',
      '$vendedor declara que el bien se encuentra libre de gravámenes, embargos, medidas cautelares, garantías mobiliarias, prenda, reserva de dominio, procesos judiciales o administrativos, denuncias de robo o pérdida, requisitorias, '
          'bloqueos y reclamos de terceros, y que no se encuentra empeñado ni dado en garantía ante ninguna persona o entidad.',
    ),
    (
      'ORIGEN LÍCITO Y PREVENCIÓN DE LAVADO DE ACTIVOS',
      '$vendedor declara que el bien tiene procedencia lícita y que no proviene de robo, hurto, estafa, receptación ni de ninguna actividad ilícita. Conoce que la adquisición de bienes de origen delictivo constituye delito (receptación, artículo 194 del Código Penal) '
          'y acepta que $comprador verifique su identidad, la titularidad y la procedencia del bien ante las autoridades y registros que corresponda, conforme a las normas de prevención del lavado de activos.',
    ),
    (
      'ESTADO CIVIL Y CONSENTIMIENTO DEL CÓNYUGE',
      '$vendedor declara su estado civil: ${d.estadoCivil.trim().isEmpty ? '____________' : d.estadoCivil.trim().toUpperCase()}. '
          '${casado ? 'Por ser casado(a) o conviviente, el bien podría pertenecer a la sociedad de gananciales; por ello su cónyuge o conviviente presta su consentimiento a esta venta firmando este documento.' : 'Declara que el bien es de su exclusiva propiedad y que no pertenece a ninguna sociedad conyugal ni unión de hecho; si esto fuera falso, asume la responsabilidad total frente a $comprador y a terceros.'}',
    ),
    if (veh)
      (
        'DOCUMENTACIÓN, DEUDAS Y TRANSFERENCIA DEL VEHÍCULO',
        '$vendedor se obliga a entregar la documentación del vehículo que posea y a firmar, en el plazo de CINCO (5) días calendario desde que $comprador se lo solicite, la minuta, formulario o escritura que se requiera, con firma legalizada ante notario, '
            'para la transferencia en SUNARP (Registro de Propiedad Vehicular) a nombre de $comprador o del tercero que éste indique. Los gastos de notaría y registro de esa transferencia serán asumidos por $comprador. '
            'Declara que el vehículo no tiene papeletas, multas, deudas de impuesto vehicular, peajes ni obligaciones pendientes; cualquier deuda anterior a la fecha de este contrato es de su exclusiva responsabilidad. '
            'Declara además que la serie, chasis y motor consignados son los que figuran en el vehículo y en su documentación.',
      )
    else
      (
        'BLOQUEOS, CUENTAS Y FUNCIONAMIENTO',
        '$vendedor declara que el artefacto no tiene bloqueo por el operador ni reporte de robo o pérdida (IMEI o serie), y que está libre de cuentas vinculadas y bloqueos de activación (por ejemplo cuentas de Google, iCloud, Samsung, contraseñas o gestión remota). '
            'Entrega las claves o códigos de desbloqueo necesarios y se obliga a retirar cualquier cuenta que quedara vinculada. Si por una cuenta o bloqueo no retirado el bien no puede usarse, $comprador podrá exigir la solución inmediata o la devolución del precio.',
      ),
    (
      'SANEAMIENTO POR EVICCIÓN',
      '$vendedor responde frente a $comprador por la evicción: si un tercero reclamara con éxito derechos sobre el bien, $vendedor devolverá el precio recibido, reembolsará los gastos en que $comprador incurra y responderá por los daños y perjuicios que se produzcan.',
    ),
    (
      'COMPRAVENTA DEFINITIVA, SIN DEVOLUCIÓN NI RECOMPRA',
      'Las partes declaran que este contrato es una COMPRAVENTA DEFINITIVA e irrevocable. NO constituye préstamo, mutuo, prenda ni garantía de ninguna clase, no genera intereses, y $vendedor NO tiene derecho a devolver el dinero para recuperar el bien, a arrepentirse, '
          'a exigir su devolución ni a pedir la recompra. Una vez firmado y pagado el precio, $comprador puede usar, exhibir, reparar y vender el bien libremente. No hay devolución del bien ni modificación del precio pactado.',
    ),
    (
      'INCUMPLIMIENTO Y RESOLUCIÓN',
      'Si cualquiera de las declaraciones de $vendedor resultara falsa, $comprador podrá resolver el contrato de pleno derecho (artículo 1430 del Código Civil) mediante carta simple o notarial, en cuyo caso $vendedor devolverá el precio recibido y '
          'pagará los gastos y la indemnización por daños y perjuicios, sin perjuicio de las acciones civiles y penales que correspondan.',
    ),
    (
      'DATOS PERSONALES, FIRMA Y HUELLA',
      '$vendedor autoriza a $comprador, conforme a la Ley N° 29733 (Ley de Protección de Datos Personales), a tratar sus datos personales, fotografías, firma e impresión de su huella digital con la finalidad de identificarlo, sustentar esta operación, cumplir obligaciones legales y atender reclamos. '
          'La firma y la huella consignadas en este documento, aun cuando se capturen digitalmente, expresan su voluntad y conformidad.',
    ),
    (
      'GASTOS Y TRIBUTOS',
      'Los tributos y gastos que correspondan a cada parte según ley serán asumidos por quien resulte obligado. Los gastos de la transferencia registral del bien, si la hubiera, se regulan por lo pactado en este contrato.',
    ),
    (
      'DOMICILIOS Y COMUNICACIONES',
      'Las partes señalan como domicilio el consignado en este documento, donde se tendrán por válidas las comunicaciones, mientras no comuniquen un cambio por escrito.',
    ),
    (
      'CONCILIACIÓN Y COMPETENCIA',
      'Cualquier controversia se tratará primero por trato directo y luego por conciliación extrajudicial (Ley N° 26872). De no resolverse, las partes se someten a los jueces y tribunales de ${d.ciudad.trim().isEmpty ? 'Atalaya' : d.ciudad.trim()}, Distrito Judicial de Ucayali.',
    ),
    (
      'CONFORMIDAD',
      'Leído el presente contrato y enterados de su contenido y alcances, las partes lo firman en señal de conformidad, en dos ejemplares del mismo tenor, en el lugar y fecha indicados.',
    ),
  ];

  final out = <w.Widget>[];
  for (var i = 0; i < items.length; i++) {
    out.add(w.SizedBox(height: 9));
    out.add(w.RichText(
      textAlign: w.TextAlign.justify,
      text: w.TextSpan(style: base, children: [
        w.TextSpan(text: 'CLÁUSULA ${_ordinal[i]} - ${items[i].$1}: ', style: neg),
        w.TextSpan(text: items[i].$2),
      ]),
    ));
    if (i == 0) {
      out.add(w.SizedBox(height: 7));
      out.add(tabla);
    }
  }
  return out;
}

/// Declaración jurada del vendedor (hoja aparte). Devuelve los widgets de la página.
List<w.Widget> declaracionJuradaCompra(DatosContrato d, w.TextStyle base, w.TextStyle neg, {required w.Widget firmaVendedor, required w.Widget firmaEmpresa}) {
  final bien = d.descripcion.trim().toUpperCase();
  final veh = d.esVehiculo;
  final ident = [
    if (d.marca.trim().isNotEmpty) 'marca ${d.marca.trim().toUpperCase()}',
    if (d.modelo.trim().isNotEmpty) 'modelo ${d.modelo.trim().toUpperCase()}',
    if (d.serie.trim().isNotEmpty) '${veh ? 'serie/chasis' : 'serie/IMEI'} ${d.serie.trim().toUpperCase()}',
    if (veh && d.placa.trim().isNotEmpty) 'placa ${d.placa.trim().toUpperCase()}',
    if (veh && d.motor.trim().isNotEmpty) 'motor ${d.motor.trim().toUpperCase()}',
  ].join(', ');
  final puntos = <String>[
    'Soy el único y legítimo propietario del bien y tengo plena facultad para venderlo. ${_documentoTexto(d)}.',
    'Adquirí el bien de forma lícita. No proviene de robo, hurto, estafa, receptación ni de ninguna actividad ilícita.',
    'El bien no tiene denuncia de robo o pérdida, requisitoria, orden de captura, bloqueo, medida cautelar ni embargo.',
    'El bien no está empeñado, prendado ni dado en garantía a ninguna persona o entidad, ni lo he vendido antes a otra persona.',
    'Mi estado civil es ${d.estadoCivil.trim().isEmpty ? '____________' : d.estadoCivil.trim().toUpperCase()}. ${['casado', 'casada', 'conviviente'].contains(d.estadoCivil.trim().toLowerCase()) ? 'Mi cónyuge o conviviente conoce y autoriza esta venta.' : 'El bien es de mi exclusiva propiedad y no pertenece a una sociedad conyugal.'}',
    if (veh)
      'El vehículo no tiene papeletas, multas, deuda de impuesto vehicular, peajes ni obligaciones pendientes. Los datos de serie, chasis, motor y placa son los reales. Me comprometo a firmar la transferencia con firma legalizada cuando se me solicite.'
    else
      'El artefacto no tiene bloqueo del operador ni reporte de robo, y está libre de cuentas vinculadas (Google, iCloud, Samsung u otras). Entrego las claves necesarias.',
    'Los datos y documentos que he entregado son verdaderos y auténticos.',
    'Sé que vendo el bien como bien de SEGUNDO USO, que esta es una compraventa definitiva y NO un préstamo, y que no hay devolución del bien, recompra ni arrepentimiento. He recibido el precio acordado a mi entera satisfacción.',
    'Autorizo la verificación de mis datos y del bien, y el tratamiento de mis datos personales, fotografías y huella digital (Ley N° 29733).',
  ];
  final out = <w.Widget>[
    w.Center(child: w.Text('DECLARACIÓN JURADA DEL VENDEDOR', style: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 13))),
    w.SizedBox(height: 14),
    w.RichText(
      textAlign: w.TextAlign.justify,
      text: w.TextSpan(style: base, children: [
        const w.TextSpan(text: 'Yo, '),
        w.TextSpan(text: d.nombre.trim().toUpperCase(), style: neg),
        const w.TextSpan(text: ', identificado(a) con DNI N° '),
        w.TextSpan(text: d.dni.trim(), style: neg),
        w.TextSpan(text: ', domiciliado(a) en ${d.domicilio.trim()}, DECLARO BAJO JURAMENTO, respecto del bien '),
        w.TextSpan(text: bien, style: neg),
        w.TextSpan(text: ident.isEmpty ? '' : ' ($ident)'),
        const w.TextSpan(text: ', que lo vendo a NEGOCIOS MULTIPLES MAYTA E.I.R.L. (RUC 20611213221), lo siguiente:'),
      ]),
    ),
    w.SizedBox(height: 8),
  ];
  for (var i = 0; i < puntos.length; i++) {
    out.add(w.SizedBox(height: 5));
    out.add(w.Text('${i + 1}. ${puntos[i]}', style: base, textAlign: w.TextAlign.justify));
  }
  out.addAll([
    w.SizedBox(height: 10),
    w.Text(
      'Formulo esta declaración con conocimiento de que, si fuera falsa, asumo la responsabilidad civil y penal que corresponda, incluidos los delitos de receptación y contra la fe pública, y que NEGOCIOS MULTIPLES MAYTA E.I.R.L. podrá usarla ante cualquier autoridad.',
      style: base,
      textAlign: w.TextAlign.justify,
    ),
    w.SizedBox(height: 14),
    w.Text('${d.ciudad.trim().isEmpty ? 'Atalaya' : d.ciudad.trim()}, ${fechaLarga(d.fecha)}', style: base, textAlign: w.TextAlign.right),
    w.SizedBox(height: 10),
    w.Row(mainAxisAlignment: w.MainAxisAlignment.spaceAround, children: [firmaVendedor, firmaEmpresa]),
  ]);
  return out;
}
