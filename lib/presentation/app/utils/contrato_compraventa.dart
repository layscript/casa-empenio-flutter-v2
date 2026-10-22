import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as w;
import 'package:printing/printing.dart';

// ---------------------------------------------------------------------------
// CONTRATO PRIVADO DE COMPRA Y VENTA (vehículo o artefacto)
// Se llena solo el nombre, los datos del bien y el precio; el texto del
// contrato ya está listo. Sale como PDF para imprimir o compartir.
// ---------------------------------------------------------------------------

const _empresa = 'NEGOCIOS MULTIPLES MAYTA E.I.R.L.';
const _ruc = '20611213221';
const _domicilioFiscal = 'CAL.URUBAMBA MZA. 8 LOTE. 8 UCAYALI - ATALAYA - RAYMONDI';

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto',
  'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

class DatosContrato {
  DatosContrato({
    required this.empresaCompra,
    required this.esVehiculo,
    required this.nombre,
    required this.dni,
    required this.domicilio,
    required this.descripcion,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.serie,
    required this.placa,
    required this.motor,
    required this.carroceria,
    required this.anio,
    required this.clase,
    required this.estado,
    required this.precio,
    required this.ciudad,
    required this.fecha,
    this.adelanto,
    this.fechaLimite,
    this.cocheraDia,
  });

  /// true: la empresa COMPRA (la persona es VENDEDOR). false: la empresa VENDE.
  final bool empresaCompra;
  final bool esVehiculo;
  final String nombre, dni, domicilio;
  final String descripcion, marca, modelo, color, serie;
  final String placa, motor, carroceria, anio, clase, estado;
  final double precio;
  final String ciudad;
  final DateTime fecha;

  /// Pago parcial: adelanto recibido y fecha límite para cancelar el saldo.
  final double? adelanto;
  final DateTime? fechaLimite;

  /// Cochera y cuidado por cada día de retraso en cancelar el saldo.
  final double? cocheraDia;

  bool get parcial => adelanto != null && adelanto! > 0 && adelanto! < precio;
  double get saldo => parcial ? precio - adelanto! : 0;
}

String fechaLarga(DateTime f) => '${f.day} de ${_meses[f.month - 1]} del ${f.year}';

// ------------------------------------------------------------ número a letras
String _centenas(int n) {
  const unidades = [
    '', 'UN', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE',
    'DIEZ', 'ONCE', 'DOCE', 'TRECE', 'CATORCE', 'QUINCE', 'DIECISEIS',
    'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE', 'VEINTE', 'VEINTIUN', 'VEINTIDOS',
    'VEINTITRES', 'VEINTICUATRO', 'VEINTICINCO', 'VEINTISEIS', 'VEINTISIETE',
    'VEINTIOCHO', 'VEINTINUEVE'
  ];
  const decenas = [
    '', '', '', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA',
    'OCHENTA', 'NOVENTA'
  ];
  const cientos = [
    '', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS',
    'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'
  ];
  if (n == 0) return '';
  if (n == 100) return 'CIEN';
  final c = n ~/ 100;
  final r = n % 100;
  final partes = <String>[];
  if (c > 0) partes.add(cientos[c]);
  if (r > 0) {
    if (r < 30) {
      partes.add(unidades[r]);
    } else {
      final d = r ~/ 10;
      final u = r % 10;
      partes.add(u == 0 ? decenas[d] : '${decenas[d]} Y ${unidades[u]}');
    }
  }
  return partes.join(' ');
}

String numeroALetras(int n) {
  if (n == 0) return 'CERO';
  final millones = n ~/ 1000000;
  final miles = (n % 1000000) ~/ 1000;
  final resto = n % 1000;
  final partes = <String>[];
  if (millones > 0) {
    partes.add(millones == 1 ? 'UN MILLON' : '${_centenas(millones)} MILLONES');
  }
  if (miles > 0) {
    partes.add(miles == 1 ? 'MIL' : '${_centenas(miles)} MIL');
  }
  if (resto > 0) partes.add(_centenas(resto));
  return partes.join(' ');
}

String precioEnLetras(double precio) {
  final entero = precio.floor();
  final cent = ((precio - entero) * 100).round();
  return '${numeroALetras(entero)} CON ${cent.toString().padLeft(2, '0')}/100 SOLES';
}

// ------------------------------------------------------------------------ PDF
Future<Uint8List> crearContratoCompraVentaPdf(
  DatosContrato d, {
  Uint8List? firmaPersona,
  Uint8List? firmaEmpresa,
  Uint8List? huellaPersona,
  String? selloDigital,
}) async {
  final pdf = w.Document();
  String v(String s) => s.trim().isEmpty ? '-' : s.trim().toUpperCase();
  final bien = d.descripcion.trim().toUpperCase();
  final persona = d.empresaCompra ? 'VENDEDOR' : 'COMPRADOR';
  final empresaRol = d.empresaCompra ? 'COMPRADOR' : 'VENDEDOR';
  final titulo = d.esVehiculo
      ? 'CONTRATO PRIVADO DE COMPRA Y VENTA DE ${d.clase.trim().isEmpty ? 'VEHICULO MENOR' : d.clase.trim().toUpperCase()}'
      : 'CONTRATO PRIVADO DE COMPRA Y VENTA DE ARTEFACTO';
  final precioTxt = NumberFormat('#,##0.00', 'en_US').format(d.precio);
  const base = w.TextStyle(fontSize: 10);
  final negrita = w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 10);

  w.TextSpan b(String t) => w.TextSpan(text: t, style: negrita);

  final cabecera = d.esVehiculo
      ? <String>['Marca', 'Modelo', 'Carroceria', 'Color', 'Motor', 'Serie', 'Placa', 'Año']
      : <String>['Marca', 'Modelo', 'Color', 'Serie / IMEI', 'Estado'];
  final fila = d.esVehiculo
      ? <String>[v(d.marca), v(d.modelo), v(d.carroceria), v(d.color), v(d.motor), v(d.serie), v(d.placa), v(d.anio)]
      : <String>[v(d.marca), v(d.modelo), v(d.color), v(d.serie), v(d.estado)];

  final firma = (String nombre, String linea2, String rol, Uint8List? firmaImg, Uint8List? huellaImg) =>
      w.Column(
        children: [
          if (firmaImg != null || huellaImg != null)
            w.SizedBox(
              height: 70,
              child: w.Row(
                mainAxisAlignment: w.MainAxisAlignment.center,
                crossAxisAlignment: w.CrossAxisAlignment.end,
                children: [
                  if (firmaImg != null) w.Image(w.MemoryImage(firmaImg), height: 60, width: 110, fit: w.BoxFit.contain),
                  if (huellaImg != null) ...[
                    w.SizedBox(width: 6),
                    w.Image(w.MemoryImage(huellaImg), height: 60, width: 50, fit: w.BoxFit.contain),
                  ],
                ],
              ),
            )
          else
            w.SizedBox(height: 70),
          w.Text('______________________', style: base),
          w.Text(nombre, style: base),
          w.Text(linea2, style: base),
          w.Text(rol, style: base),
          if (huellaImg != null) w.Text('(huella índice derecho)', style: const w.TextStyle(fontSize: 7)),
        ],
      );

  pdf.addPage(
    w.Page(
      pageFormat: p.PdfPageFormat.a4,
      margin: const w.EdgeInsets.all(40),
      build: (ctx) => w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Center(
            child: w.Text(d.parcial ? '$titulo\n(CON ADELANTO Y PAGO PARCIAL)' : titulo,
                textAlign: w.TextAlign.center,
                style: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 13)),
          ),
          w.SizedBox(height: 25),
          w.RichText(
            textAlign: w.TextAlign.justify,
            text: w.TextSpan(style: base, children: [
              const w.TextSpan(text: 'Consta por el presente documento de compra y venta de '),
              b(bien),
              if (d.marca.trim().isNotEmpty) ...[
                const w.TextSpan(text: ', de marca '),
                b(d.marca.trim().toUpperCase()),
              ],
              if (d.esVehiculo && d.placa.trim().isNotEmpty) ...[
                const w.TextSpan(text: ', con placa '),
                b(d.placa.trim().toUpperCase()),
              ],
              const w.TextSpan(text: ', que celebran de una parte el Sr(a). '),
              b(d.nombre.trim().toUpperCase()),
              const w.TextSpan(text: ', identificado(a) con DNI N° '),
              b(d.dni.trim()),
              w.TextSpan(
                  text:
                      ', domiciliado(a) en ${d.domicilio.trim()}, en lo que sigue del presente contrato será llamado EL $persona, y de la otra parte la empresa '),
              b(_empresa),
              const w.TextSpan(text: ' con RUC '),
              b(_ruc),
              w.TextSpan(
                  text:
                      ', con domicilio fiscal en $_domicilioFiscal, quien en adelante será llamado EL $empresaRol, según las cláusulas siguientes:'),
            ]),
          ),
          w.SizedBox(height: 15),
          w.Text(
            '- PRIMERO: EL VENDEDOR declara bajo juramento ser el propietario del bien: $bien, con las características siguientes:',
            style: base,
          ),
          w.SizedBox(height: 12),
          w.TableHelper.fromTextArray(
            context: ctx,
            cellStyle: const w.TextStyle(fontSize: 9),
            cellAlignment: w.Alignment.centerLeft,
            data: <List<String>>[cabecera, fila],
          ),
          w.SizedBox(height: 15),
          w.Text(
            d.parcial
                ? '- SEGUNDO: El precio pactado por la compra y venta del bien al que se refiere la cláusula anterior es de S/. $precioTxt (${precioEnLetras(d.precio)}), que EL COMPRADOR cancela de la siguiente manera: a) S/. ${NumberFormat('#,##0.00', 'en_US').format(d.adelanto)} (${precioEnLetras(d.adelanto!)}) como ADELANTO, recibido en este acto a entera satisfacción; y b) el SALDO de S/. ${NumberFormat('#,##0.00', 'en_US').format(d.saldo)} (${precioEnLetras(d.saldo)}), que EL COMPRADOR se obliga a cancelar a más tardar el ${d.fechaLimite != null ? fechaLarga(d.fechaLimite!) : '__________'}, fecha en la que recogerá el bien.'
                : '- SEGUNDO: El precio pactado por la compra y venta del bien al que se refiere la cláusula anterior es de S/. $precioTxt (${precioEnLetras(d.precio)}), pagados al contado; EL VENDEDOR declara haber recibido el monto en soles a su entera satisfacción.',
            style: base,
            textAlign: w.TextAlign.justify,
          ),
          w.SizedBox(height: 15),
          w.Text(
            d.parcial
                ? (d.esVehiculo
                    ? '- TERCERO: El bien permanecerá en custodia de EL VENDEDOR hasta la cancelación total del precio. Una vez cancelado el saldo, EL COMPRADOR recibirá el vehículo a su entera satisfacción y sin responsabilidades para EL VENDEDOR en la parte técnica mecánica, por ser un vehículo usado. La cancelación se hará constar en una constancia firmada por ambas partes.'
                    : '- TERCERO: El bien permanecerá en custodia de EL VENDEDOR hasta la cancelación total del precio. Una vez cancelado el saldo, EL COMPRADOR recibirá el artefacto a su entera satisfacción, en el estado en que se encuentra, y sin responsabilidades para EL VENDEDOR por su funcionamiento, por ser un bien usado. La cancelación se hará constar en una constancia firmada por ambas partes.')
                : (d.esVehiculo
                    ? '- TERCERO: Igualmente EL COMPRADOR declara haber recibido el vehículo materia de este contrato a su entera satisfacción y sin responsabilidades para EL VENDEDOR en la parte técnica mecánica, por ser un vehículo usado.'
                    : '- TERCERO: Igualmente EL COMPRADOR declara haber recibido el artefacto materia de este contrato a su entera satisfacción, en el estado en que se encuentra, y sin responsabilidades para EL VENDEDOR por su funcionamiento, por ser un bien usado.'),
            style: base,
            textAlign: w.TextAlign.justify,
          ),
          if (d.parcial) ...[
            w.SizedBox(height: 15),
            w.Text(
              '- CUARTO: Vencido el plazo señalado en la cláusula segunda sin que EL COMPRADOR haya cancelado el saldo y recogido el bien, queda obligado a pagar por concepto de cochera y gastos de cuidado del bien '
              '${(d.cocheraDia ?? 0) > 0 ? 'la suma de S/. ${NumberFormat('#,##0.00', 'en_US').format(d.cocheraDia)} (${precioEnLetras(d.cocheraDia!)}) por cada día de retraso' : 'el monto que ambas partes acuerden'}, '
              'además del saldo del precio.',
              style: base,
              textAlign: w.TextAlign.justify,
            ),
          ],
          w.SizedBox(height: 15),
          w.SizedBox(
            width: double.infinity,
            child: w.Text(
              '${d.ciudad.trim().isEmpty ? 'Atalaya' : d.ciudad.trim()}, ${d.fecha.day} de ${_meses[d.fecha.month - 1]} del ${d.fecha.year}',
              textAlign: w.TextAlign.right,
              style: base,
            ),
          ),
          w.SizedBox(height: 15),
          w.Row(
            mainAxisAlignment: w.MainAxisAlignment.spaceAround,
            children: [
              firma(d.nombre.trim().toUpperCase(), 'DNI N° ${d.dni.trim()}', persona, firmaPersona, huellaPersona),
              firma(_empresa, 'RUC $_ruc', empresaRol, firmaEmpresa, null),
            ],
          ),
          if (selloDigital != null) ...[
            w.SizedBox(height: 18),
            w.Text(selloDigital, style: const w.TextStyle(fontSize: 8)),
          ],
        ],
      ),
    ),
  );
  return pdf.save();
}

// ------------------------------------------------- CONSTANCIA DE CANCELACIÓN
/// Se firma cuando el cliente vuelve a cancelar el saldo y recoge el bien.
Future<Uint8List> crearConstanciaCancelacionPdf(
  DatosContrato d, {
  required DateTime fechaContrato,
  double recargo = 0,
  Uint8List? firmaPersona,
  Uint8List? firmaEmpresa,
  Uint8List? huellaPersona,
  String? selloDigital,
}) async {
  final pdf = w.Document();
  String m(double v) => NumberFormat('#,##0.00', 'en_US').format(v);
  const base = w.TextStyle(fontSize: 10);
  final neg = w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 10);
  final persona = d.empresaCompra ? 'VENDEDOR' : 'COMPRADOR';
  final empresaRol = d.empresaCompra ? 'COMPRADOR' : 'VENDEDOR';
  final bien = d.descripcion.trim().toUpperCase();
  final saldo = d.saldo;
  w.Widget firma(String n, String l2, String rol, Uint8List? f, Uint8List? h) => w.Column(children: [
        if (f != null || h != null)
          w.SizedBox(
            height: 70,
            child: w.Row(
              mainAxisAlignment: w.MainAxisAlignment.center,
              crossAxisAlignment: w.CrossAxisAlignment.end,
              children: [
                if (f != null) w.Image(w.MemoryImage(f), height: 60, width: 110, fit: w.BoxFit.contain),
                if (h != null) ...[
                  w.SizedBox(width: 6),
                  w.Image(w.MemoryImage(h), height: 60, width: 50, fit: w.BoxFit.contain),
                ],
              ],
            ),
          )
        else
          w.SizedBox(height: 70),
        w.Text('______________________', style: base),
        w.Text(n, style: base),
        w.Text(l2, style: base),
        w.Text(rol, style: base),
      ]);
  pdf.addPage(
    w.Page(
      pageFormat: p.PdfPageFormat.a4,
      margin: const w.EdgeInsets.all(40),
      build: (ctx) => w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Center(
            child: w.Text('CONSTANCIA DE CANCELACIÓN Y ENTREGA',
                style: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 13)),
          ),
          w.SizedBox(height: 22),
          w.RichText(
            textAlign: w.TextAlign.justify,
            text: w.TextSpan(style: base, children: [
              const w.TextSpan(text: 'Por el presente documento, el(la) Sr(a). '),
              w.TextSpan(text: d.nombre.trim().toUpperCase(), style: neg),
              const w.TextSpan(text: ', identificado(a) con DNI N° '),
              w.TextSpan(text: d.dni.trim(), style: neg),
              w.TextSpan(
                  text:
                      ', en su calidad de EL $persona, deja constancia de que ha CANCELADO el saldo de S/. ${m(saldo)} (${precioEnLetras(saldo)}) '
                      'del contrato privado de compra y venta de fecha ${fechaLarga(fechaContrato)}, celebrado con la empresa '),
              w.TextSpan(text: _empresa, style: neg),
              w.TextSpan(
                  text:
                      ' (RUC $_ruc), en su calidad de EL $empresaRol, respecto del bien: '),
              w.TextSpan(text: bien, style: neg),
              w.TextSpan(
                  text:
                      '${d.marca.trim().isNotEmpty ? ', marca ${d.marca.trim().toUpperCase()}' : ''}'
                      '${d.serie.trim().isNotEmpty ? ', serie ${d.serie.trim().toUpperCase()}' : ''}'
                      '${d.placa.trim().isNotEmpty ? ', placa ${d.placa.trim().toUpperCase()}' : ''}.'),
            ]),
          ),
          w.SizedBox(height: 14),
          w.Text(
            'Con el adelanto de S/. ${m(d.adelanto ?? 0)} entregado al firmar el contrato y este último pago, el precio total de S/. ${m(d.precio)} (${precioEnLetras(d.precio)}) queda CANCELADO EN SU TOTALIDAD.'
            '${recargo > 0 ? ' Además, EL COMPRADOR pagó S/. ${m(recargo)} (${precioEnLetras(recargo)}) por concepto de cochera y gastos de cuidado del bien por el retraso en la cancelación.' : ''}',
            style: base,
            textAlign: w.TextAlign.justify,
          ),
          w.SizedBox(height: 14),
          w.Text(
            'EL COMPRADOR declara haber recibido el bien a su entera satisfacción, en el estado en que se encuentra, y sin responsabilidad alguna para EL VENDEDOR. Con esta constancia el contrato de compra y venta queda CONCLUIDO.',
            style: base,
            textAlign: w.TextAlign.justify,
          ),
          w.SizedBox(height: 16),
          w.SizedBox(
            width: double.infinity,
            child: w.Text(
              '${d.ciudad.trim().isEmpty ? 'Atalaya' : d.ciudad.trim()}, ${fechaLarga(d.fecha)}',
              textAlign: w.TextAlign.right,
              style: base,
            ),
          ),
          w.SizedBox(height: 15),
          w.Row(
            mainAxisAlignment: w.MainAxisAlignment.spaceAround,
            children: [
              firma(d.nombre.trim().toUpperCase(), 'DNI N° ${d.dni.trim()}', persona, firmaPersona, huellaPersona),
              firma(_empresa, 'RUC $_ruc', empresaRol, firmaEmpresa, null),
            ],
          ),
          if (selloDigital != null) ...[
            w.SizedBox(height: 18),
            w.Text(selloDigital, style: const w.TextStyle(fontSize: 8)),
          ],
        ],
      ),
    ),
  );
  return pdf.save();
}

// ------------------------------------------------ CONSTANCIA DE DESISTIMIENTO
/// Se firma cuando el cliente se arrepiente y se le devuelve su adelanto.
Future<Uint8List> crearConstanciaDesistimientoPdf(
  DatosContrato d, {
  required DateTime fechaContrato,
  required double retenido,
  String motivo = '',
  Uint8List? firmaPersona,
  Uint8List? firmaEmpresa,
  Uint8List? huellaPersona,
  String? selloDigital,
}) async {
  final pdf = w.Document();
  String m(double v) => NumberFormat('#,##0.00', 'en_US').format(v);
  const base = w.TextStyle(fontSize: 10);
  final neg = w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 10);
  final adel = d.adelanto ?? 0;
  final devuelto = adel - retenido;
  w.Widget firma(String n, String l2, String rol, Uint8List? f, Uint8List? h) => w.Column(children: [
        if (f != null || h != null)
          w.SizedBox(
            height: 70,
            child: w.Row(
              mainAxisAlignment: w.MainAxisAlignment.center,
              crossAxisAlignment: w.CrossAxisAlignment.end,
              children: [
                if (f != null) w.Image(w.MemoryImage(f), height: 60, width: 110, fit: w.BoxFit.contain),
                if (h != null) ...[
                  w.SizedBox(width: 6),
                  w.Image(w.MemoryImage(h), height: 60, width: 50, fit: w.BoxFit.contain),
                ],
              ],
            ),
          )
        else
          w.SizedBox(height: 70),
        w.Text('______________________', style: base),
        w.Text(n, style: base),
        w.Text(l2, style: base),
        w.Text(rol, style: base),
      ]);
  pdf.addPage(
    w.Page(
      pageFormat: p.PdfPageFormat.a4,
      margin: const w.EdgeInsets.all(40),
      build: (ctx) => w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Center(
            child: w.Text('CONSTANCIA DE DESISTIMIENTO Y DEVOLUCIÓN',
                style: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 13)),
          ),
          w.SizedBox(height: 22),
          w.RichText(
            textAlign: w.TextAlign.justify,
            text: w.TextSpan(style: base, children: [
              const w.TextSpan(text: 'Por el presente documento, el(la) Sr(a). '),
              w.TextSpan(text: d.nombre.trim().toUpperCase(), style: neg),
              const w.TextSpan(text: ', identificado(a) con DNI N° '),
              w.TextSpan(text: d.dni.trim(), style: neg),
              w.TextSpan(
                  text:
                      ', manifiesta de manera voluntaria que DESISTE de la compra del bien '),
              w.TextSpan(text: d.descripcion.trim().toUpperCase(), style: neg),
              w.TextSpan(
                  text:
                      '${d.serie.trim().isNotEmpty ? ' (serie ${d.serie.trim().toUpperCase()})' : ''}${d.placa.trim().isNotEmpty ? ' (placa ${d.placa.trim().toUpperCase()})' : ''}'
                      ', pactada en el contrato privado de compra y venta de fecha ${fechaLarga(fechaContrato)} con la empresa '),
              w.TextSpan(text: _empresa, style: neg),
              w.TextSpan(text: ' (RUC $_ruc), por el precio de S/. ${m(d.precio)}.'),
            ]),
          ),
          w.SizedBox(height: 14),
          w.Text(
            'El adelanto entregado fue de S/. ${m(adel)} (${precioEnLetras(adel)}). '
            '${retenido > 0 ? 'La empresa retiene S/. ${m(retenido)} (${precioEnLetras(retenido)}) por concepto de gastos de cochera y cuidado del bien, y ' : ''}'
            'devuelve a EL COMPRADOR la suma de S/. ${m(devuelto)} (${precioEnLetras(devuelto)}), que recibe en este acto a su entera conformidad.',
            style: base,
            textAlign: w.TextAlign.justify,
          ),
          if (motivo.trim().isNotEmpty) ...[
            w.SizedBox(height: 10),
            w.Text('Motivo: ${motivo.trim()}', style: base),
          ],
          w.SizedBox(height: 14),
          w.Text(
            'Con la firma de este documento el contrato de compra y venta queda SIN EFECTO, el bien queda a disposición de la empresa y ninguna de las partes tiene reclamo pendiente contra la otra.',
            style: base,
            textAlign: w.TextAlign.justify,
          ),
          w.SizedBox(height: 16),
          w.SizedBox(
            width: double.infinity,
            child: w.Text(
              '${d.ciudad.trim().isEmpty ? 'Atalaya' : d.ciudad.trim()}, ${fechaLarga(d.fecha)}',
              textAlign: w.TextAlign.right,
              style: base,
            ),
          ),
          w.SizedBox(height: 15),
          w.Row(
            mainAxisAlignment: w.MainAxisAlignment.spaceAround,
            children: [
              firma(d.nombre.trim().toUpperCase(), 'DNI N° ${d.dni.trim()}', 'COMPRADOR', firmaPersona, huellaPersona),
              firma(_empresa, 'RUC $_ruc', 'VENDEDOR', firmaEmpresa, null),
            ],
          ),
          if (selloDigital != null) ...[
            w.SizedBox(height: 18),
            w.Text(selloDigital, style: const w.TextStyle(fontSize: 8)),
          ],
        ],
      ),
    ),
  );
  return pdf.save();
}

/// Manda el PDF directo a imprimir (abre el diálogo de impresión del teléfono).
Future<void> imprimirPdf(Uint8List bytes, String nombre) async {
  await Printing.layoutPdf(
    name: nombre,
    format: p.PdfPageFormat.a4,
    onLayout: (_) async => bytes,
  );
}

/// Abre una vista previa de PDF (imprimir / compartir).
void abrirVistaPdf(
  BuildContext context, {
  required String titulo,
  required String archivo,
  required Future<Uint8List> Function() build,
}) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(titulo)),
        body: PdfPreview(
          pdfFileName: archivo,
          initialPageFormat: p.PdfPageFormat.a4,
          pageFormats: const <String, p.PdfPageFormat>{'A4': p.PdfPageFormat.a4},
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          build: (_) => build(),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- PROFORMA
// Cotización de venta (no es comprobante de pago). Sin IGV: es un precio final.
Future<Uint8List> crearProformaPdf(DatosContrato d) async {
  final pdf = w.Document();
  String v(String s) => s.trim().isEmpty ? '-' : s.trim().toUpperCase();
  final precio = NumberFormat('#,##0.00', 'en_US').format(d.precio);
  final f = '${d.fecha.day.toString().padLeft(2, '0')}/${d.fecha.month.toString().padLeft(2, '0')}/${d.fecha.year}';
  final detalle = <String>[
    d.descripcion.trim().toUpperCase(),
    if (d.marca.trim().isNotEmpty) 'MARCA: ${d.marca.trim().toUpperCase()}',
    if (d.modelo.trim().isNotEmpty) 'MODELO: ${d.modelo.trim().toUpperCase()}',
    if (d.color.trim().isNotEmpty) 'COLOR: ${d.color.trim().toUpperCase()}',
    if (d.serie.trim().isNotEmpty) 'SERIE: ${d.serie.trim().toUpperCase()}',
    if (d.placa.trim().isNotEmpty) 'PLACA: ${d.placa.trim().toUpperCase()}',
    if (d.motor.trim().isNotEmpty) 'MOTOR: ${d.motor.trim().toUpperCase()}',
  ].join('\n');
  const base = w.TextStyle(fontSize: 10);
  final neg = w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 10);
  pdf.addPage(
    w.Page(
      pageFormat: p.PdfPageFormat.a4,
      margin: const w.EdgeInsets.all(40),
      build: (ctx) => w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text(_empresa, style: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 14)),
          w.Text('RUC $_ruc', style: base),
          w.Text(_domicilioFiscal, style: base),
          w.SizedBox(height: 22),
          w.Center(
            child: w.Text('PROFORMA DE VENTA',
                style: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 15)),
          ),
          w.SizedBox(height: 18),
          w.Text('Fecha: $f', style: base),
          w.Text('Cliente: ${v(d.nombre)}', style: neg),
          w.Text('DNI / RUC: ${v(d.dni)}', style: base),
          w.Text('Domicilio: ${v(d.domicilio)}', style: base),
          w.SizedBox(height: 18),
          w.TableHelper.fromTextArray(
            context: ctx,
            cellStyle: const w.TextStyle(fontSize: 10),
            headerStyle: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 10),
            cellAlignment: w.Alignment.centerLeft,
            data: <List<String>>[
              ['Cant.', 'Descripción', 'Precio (S/.)'],
              ['1', detalle, precio],
            ],
          ),
          w.SizedBox(height: 12),
          w.Align(
            alignment: w.Alignment.centerRight,
            child: w.Text('TOTAL: S/. $precio', style: w.TextStyle(fontWeight: w.FontWeight.bold, fontSize: 12)),
          ),
          w.Align(
            alignment: w.Alignment.centerRight,
            child: w.Text('(${precioEnLetras(d.precio)})', style: base),
          ),
          w.SizedBox(height: 22),
          w.Text(
            'Este documento es una cotización y no constituye comprobante de pago. '
            'Precio sujeto a disponibilidad del bien. Validez: 3 días.',
            style: const w.TextStyle(fontSize: 9),
          ),
        ],
      ),
    ),
  );
  return pdf.save();
}

// ------------------------------------------------------------------ pantalla
class ContratoCompraVentaPage extends StatefulWidget {
  const ContratoCompraVentaPage({
    super.key,
    this.prellenado,
    this.esVehiculoInicial = true,
    this.empresaCompraInicial = true,
  });

  final bool esVehiculoInicial;
  final bool empresaCompraInicial;

  /// Datos ya conocidos del bien (por ejemplo, de un producto del almacén).
  final Map<String, String>? prellenado;

  @override
  State<ContratoCompraVentaPage> createState() => _ContratoCompraVentaPageState();
}

class _ContratoCompraVentaPageState extends State<ContratoCompraVentaPage> {
  late bool _empresaCompra = widget.empresaCompraInicial;
  late bool _esVehiculo = widget.esVehiculoInicial;
  DateTime _fecha = DateTime.now();
  final _c = <String, TextEditingController>{};
  String? _error;

  TextEditingController c(String k) => _c.putIfAbsent(
      k,
      () => TextEditingController(
          text: widget.prellenado?[k] ?? (k == 'ciudad' ? 'Atalaya' : (k == 'clase' ? 'Vehículo menor' : ''))));

  @override
  void dispose() {
    for (final x in _c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Widget campo(String k, String etiqueta,
      {TextInputType? tipo, String? prefijo, TextCapitalization cap = TextCapitalization.words}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c(k),
        keyboardType: tipo,
        textCapitalization: cap,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixText: prefijo,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget titulo(String t, [String? sub]) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (sub != null)
              Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );

  void _generar() {
    String? falta;
    if (c('nombre').text.trim().isEmpty) {
      falta = 'Escriba el nombre completo';
    } else if (c('dni').text.trim().isEmpty) {
      falta = 'Escriba el DNI';
    } else if (c('descripcion').text.trim().isEmpty) {
      falta = _esVehiculo ? 'Escriba qué vehículo es (ej. Moto lineal)' : 'Escriba qué artefacto es (ej. Televisor)';
    } else if (double.tryParse(c('precio').text.replaceAll(',', '.')) == null) {
      falta = 'Escriba el precio';
    }
    if (falta != null) {
      setState(() => _error = falta);
      return;
    }
    setState(() => _error = null);
    final datos = DatosContrato(
      empresaCompra: _empresaCompra,
      esVehiculo: _esVehiculo,
      nombre: c('nombre').text,
      dni: c('dni').text,
      domicilio: c('domicilio').text,
      descripcion: c('descripcion').text,
      marca: c('marca').text,
      modelo: c('modelo').text,
      color: c('color').text,
      serie: c('serie').text,
      placa: c('placa').text,
      motor: c('motor').text,
      carroceria: c('carroceria').text,
      anio: c('anio').text,
      clase: c('clase').text,
      estado: c('estado').text,
      precio: double.parse(c('precio').text.replaceAll(',', '.')),
      ciudad: c('ciudad').text,
      fecha: _fecha,
    );
    abrirVistaPdf(
      context,
      titulo: 'Contrato listo',
      archivo: 'Contrato_${c('nombre').text.trim().replaceAll(' ', '_')}.pdf',
      build: () => crearContratoCompraVentaPdf(datos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Contrato de compra y venta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          titulo('1. ¿Qué se hace?'),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('La empresa COMPRA'), icon: Icon(Icons.download)),
              ButtonSegment(value: false, label: Text('La empresa VENDE'), icon: Icon(Icons.upload)),
            ],
            selected: {_empresaCompra},
            onSelectionChanged: (s) => setState(() => _empresaCompra = s.first),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Vehículo'), icon: Icon(Icons.two_wheeler)),
              ButtonSegment(value: false, label: Text('Artefacto'), icon: Icon(Icons.devices_other)),
            ],
            selected: {_esVehiculo},
            onSelectionChanged: (s) => setState(() => _esVehiculo = s.first),
          ),
          titulo(
            '2. Datos de la persona',
            _empresaCompra ? 'Será EL VENDEDOR (nos vende)' : 'Será EL COMPRADOR (nos compra)',
          ),
          campo('nombre', 'Nombre completo'),
          campo('dni', 'DNI', tipo: TextInputType.number),
          campo('domicilio', 'Domicilio'),
          titulo('3. Datos del ${_esVehiculo ? 'vehículo' : 'artefacto'}', 'Deje en blanco lo que no tenga.'),
          if (_esVehiculo) campo('clase', 'Clase de vehículo (sale en el título)'),
          campo('descripcion', _esVehiculo ? 'Vehículo (ej. Moto lineal, Mototaxi)' : 'Artefacto (ej. Televisor, Celular)'),
          campo('marca', 'Marca'),
          campo('modelo', 'Modelo'),
          campo('color', 'Color'),
          if (_esVehiculo) ...[
            campo('carroceria', 'Carrocería'),
            campo('motor', 'Motor N°', cap: TextCapitalization.characters),
            campo('serie', 'Serie / Chasis', cap: TextCapitalization.characters),
            campo('placa', 'Placa', cap: TextCapitalization.characters),
            campo('anio', 'Año', tipo: TextInputType.number),
          ] else ...[
            campo('serie', 'Serie / IMEI', cap: TextCapitalization.characters),
            campo('estado', 'Estado (ej. usado, buen estado)'),
          ],
          titulo('4. Precio y fecha'),
          campo('precio', 'Precio pactado', tipo: const TextInputType.numberWithOptions(decimal: true), prefijo: 'S/. '),
          campo('ciudad', 'Ciudad'),
          OutlinedButton.icon(
            onPressed: () async {
              final r = await showDatePicker(
                context: context,
                initialDate: _fecha,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (r != null) setState(() => _fecha = r);
            },
            icon: const Icon(Icons.event),
            label: Text('Fecha del contrato: ${fmt.format(_fecha)}'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _generar,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Ver contrato (PDF)'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Desde la vista del PDF puede imprimir o compartir por WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
