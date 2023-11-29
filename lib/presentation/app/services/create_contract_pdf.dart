import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

abstract class CreateContractPdf {
  static Future<Uint8List> crearContratoPdf(ContratoEntity contrato) async {
    final pdf = Document();

    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    const double textSize = 9.0;

    pdf.addPage(
      //   Page(
      //       pageFormat: PdfPageFormat.a4,
      //       build: (Context context) {
      //         final fecha = DateTime.now();
      //         return Container(
      //           child: Column(
      //             mainAxisAlignment: MainAxisAlignment.start,
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //               Text(
      //                 'CONTRATO DE PRESTAMO PRENDARIO CON CONDICION DE COMPRA Y VENTA N° ${contrato.numero.toString().padLeft(6, '0')}',
      //                 textAlign: TextAlign.center,
      //                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      //               ),
      //               SizedBox(
      //                 height: 15,
      //               ),
      //               SizedBox(
      //                 width: double.infinity,
      //                 child: Text(
      //                   // '19 de noviembre del 2022',
      //                   '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}',
      //                   textAlign: TextAlign.right,
      //                   style: const TextStyle(fontSize: 10),
      //                 ),
      //               ),
      //               SizedBox(
      //                 height: 25,
      //               ),
      //               RichText(
      //                 textAlign: TextAlign.justify,
      //                 text: TextSpan(
      //                   style: TextStyle(fontSize: 10),
      //                   children: [
      //                     TextSpan(text: 'Señor(a) '),
      //                     TextSpan(
      //                       text: contrato.nombre.toUpperCase(),
      //                       style: TextStyle(fontWeight: FontWeight.bold),
      //                     ),
      //                     TextSpan(text: ', con DNI '),
      //                     TextSpan(
      //                       text: contrato.dni,
      //                       style: TextStyle(fontWeight: FontWeight.bold),
      //                     ),
      //                     TextSpan(
      //                         text:
      //                             ', domiciliado en ${contrato.domicilio.toUpperCase()}. Solicita un préstamo de '),
      //                     TextSpan(
      //                       text:
      //                           // '1000 soles con fecha de vencimiento 28/11/2022, devolviendo un total de 1200 soles.',
      //                           '${contrato.monto.toStringAsFixed(2)} soles con fecha de vencimiento ${contrato.fechaVencimiento.day.toString().padLeft(2, '0')}/${contrato.fechaVencimiento.month.toString().padLeft(2, '0')}/${contrato.fechaVencimiento.year}, devolviendo un total de ${contrato.montoPagar.toStringAsFixed(2)} soles.',
      //                       style: TextStyle(fontWeight: FontWeight.bold),
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //               SizedBox(
      //                 height: 15,
      //               ),
      //               Text(
      //                 'Dejando las siguientes prendas en garantía con las características.',
      //                 style: const TextStyle(fontSize: 10),
      //               ),
      //               SizedBox(
      //                 height: 15,
      //               ),
      //               // generar lista de productos
      //               Table.fromTextArray(
      //                 context: context,
      //                 cellStyle: TextStyle(fontSize: 9),
      //                 cellAlignment: Alignment.centerLeft,
      //                 columnWidths: {
      //                   0: FixedColumnWidth(110),
      //                   1: FixedColumnWidth(40),
      //                   2: FixedColumnWidth(40),
      //                   3: FixedColumnWidth(40),
      //                   4: FixedColumnWidth(40),
      //                   5: FixedColumnWidth(40),
      //                 },
      //                 data: <List<String>>[
      //                   <String>[
      //                     'Nombre',
      //                     'Marca',
      //                     'Modelo',
      //                     'Serie',
      //                     'Color',
      //                     'Estado'
      //                   ],
      //                   // <String>[
      //                   //   'TELEVISOR 60 PULGADAS',
      //                   //   'SAMSUNG',
      //                   //   'ABC',
      //                   //   '987654321',
      //                   //   'NEGRO',
      //                   //   'REGULAR'
      //                   // ],
      //                   ...contrato.prendas
      //                       .map((e) => [
      //                             e.nombre.toUpperCase(),
      //                             e.marca.toUpperCase(),
      //                             e.modelo.toUpperCase(),
      //                             e.serie.toUpperCase(),
      //                             e.color.toUpperCase(),
      //                             e.estado.toUpperCase()
      //                           ])
      //                       .toList()
      //                 ],
      //               ),
      //               SizedBox(
      //                 height: 15,
      //               ),
      //               Text(
      //                 'La casa de INVERSIONES MAYTA no se responsabiliza de los mantenimientos y degradación de cualquier mueble, motor, artefacto, vehículo, entre otros.',
      //                 style: const TextStyle(fontSize: 10),
      //               ),
      //               SizedBox(
      //                 height: 15,
      //               ),
      //               Text(
      //                 'CONDICIONES CONTRACTUALES: EL CLIENTE ACEPTA LAS SIGUIENTES CONDICIONES:',
      //                 style: const TextStyle(fontSize: 10),
      //               ),
      //               SizedBox(
      //                 height: 15,
      //               ),
      //               // GENERAR LISTA ENUMERADA
      //               Container(
      //                 padding: const EdgeInsets.only(left: 20),
      //                 child: Column(
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   children: [
      //                     Text(
      //                       '1. EL CLIENTE declara abandonado el producto pasado los 7 días de la fecha de vencimiento del contrato.',
      //                       style: const TextStyle(fontSize: 10),
      //                       textAlign: TextAlign.justify,
      //                     ),
      //                     SizedBox(
      //                       height: 5,
      //                     ),
      //                     Text(
      //                       '2. EL CLIENTE autoriza expresamente a entregar el producto indicado en este contrato al portador de este comprobante.',
      //                       style: const TextStyle(fontSize: 10),
      //                       textAlign: TextAlign.justify,
      //                     ),
      //                     SizedBox(
      //                       height: 5,
      //                     ),
      //                     Text(
      //                       '3. EL CLIENTE declara bajo juramento que es propietario del inmueble sometiéndose a las sanciones respectivas según la ley 27482 - 27444.',
      //                       style: const TextStyle(fontSize: 10),
      //                       textAlign: TextAlign.justify,
      //                     ),
      //                     SizedBox(
      //                       height: 5,
      //                     ),
      //                     Text(
      //                       '4. EL CLIENTE acepta las condiciones de pago del interés, chochera, guardianía y comisiones entre otros.',
      //                       style: const TextStyle(fontSize: 10),
      //                       textAlign: TextAlign.justify,
      //                     ),
      //                     SizedBox(
      //                       height: 5,
      //                     ),
      //                     Text(
      //                       '5. Si el mueble aun esta en el local a pesar de haber vencido el cliente pagara 1% diario del total de la deuda.',
      //                       style: const TextStyle(fontSize: 10),
      //                       textAlign: TextAlign.justify,
      //                     ),
      //                     SizedBox(
      //                       height: 5,
      //                     ),
      //                     Text(
      //                       '6. Al no cumplir con el pago parcial o total El cliente acepta que esta firma es válida como contrato de compra y venta del mueble a favor de la CASA de INVERSIONES MAYTA.',
      //                       style: const TextStyle(fontSize: 10),
      //                       textAlign: TextAlign.justify,
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //               SizedBox(
      //                 height: 15,
      //               ),
      //               // GENERAR 2 COLUMNAS PARA DOS FIRMAS
      //               Row(
      //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
      //                 children: [
      //                   Column(
      //                     children: [
      //                       SizedBox(
      //                         height: 70,
      //                       ),
      //                       Text(
      //                         '_________',
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                       Text(
      //                         'FIRMA DEL CLIENTE',
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                       Text(
      //                         contrato.nombre,
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                       Text(
      //                         'DNI: ${contrato.dni}',
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                     ],
      //                   ),
      //                   Column(
      //                     children: [
      //                       SizedBox(
      //                         height: 70,
      //                       ),
      //                       Text(
      //                         '_________',
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                       Text(
      //                         'NEGOCIOS MULTIPLES MAYTA E.I.R.L.',
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                       Text(
      //                         'JOEL MAYCO MAYTA TORRE',
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                       Text(
      //                         'RUC: 20611213221',
      //                         style: const TextStyle(fontSize: 10),
      //                       ),
      //                     ],
      //                   ),
      //                 ],
      //               ),
      //               contrato.nombreAval != ''
      //                   ? Row(
      //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //                       children: [
      //                         Column(
      //                           children: [
      //                             SizedBox(
      //                               height: 60,
      //                             ),
      //                             Text(
      //                               '_________',
      //                               style: const TextStyle(fontSize: 10),
      //                             ),
      //                             Text(
      //                               'FIRMA DEL AVAL',
      //                               style: const TextStyle(fontSize: 10),
      //                             ),
      //                             Text(
      //                               contrato.nombreAval,
      //                               style: const TextStyle(fontSize: 10),
      //                             ),
      //                             Text(
      //                               'DNI: ${contrato.dniAval}',
      //                               style: const TextStyle(fontSize: 10),
      //                             ),
      //                           ],
      //                         ),
      //                       ],
      //                     )
      //                   : SizedBox(),
      //             ],
      //           ),
      //         );
      //       }),
      // );
      Page(
          pageFormat: PdfPageFormat.a4,
          build: (Context context) {
            final fecha = DateTime.now();
            return Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTRATO DE MUTUO A TÍTULO ONEROSO CON GARANTÍA PRENDARIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      style: const TextStyle(fontSize: textSize),
                      children: [
                        const TextSpan(
                            text:
                                'Por el presente documento se hace constar el contrato de MUTUO CON GARANTÍA PRENDARIA DE "VEHÍCULOS, ARTEFACTOS Y OTROS", que celebran de una parte como el MUTUANTE, NEGOCIOS MÚLTIPLES MAYTA EIRL, identificado con RUC N° 20611213221, debidamente representado por su representante legal, MAYTA TORRE JOEL MAYCO, identificado con DNI N° 46864068, con domicilio fiscal sito en CALLE URUBAMBA MZ 8 LOTE 8 - UCAYALI - ATALAYA; y de la otra parte como EL(LA) MUTUATARIO(A), el(la) Sr(a) '),
                        TextSpan(
                          text: contrato.nombre.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ', identificado(a) con DNI N°'),
                        TextSpan(
                          text: contrato.dni,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                            text:
                                ' con domicilio en ${contrato.domicilio.toUpperCase()}, de acuerdo a los términos y condiciones siguientes:'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'PRIMERA: ANTECEDENTES - EL MUTUANTE es una persona jurídica que se dedica a la actividad de prestación de toda clase de servicios financieros, otorgando o colocando créditos mediante préstamos con garantías reales y otros, con aplicación de tasas de interés acorde a las disposiciones vigentes, créditos dirigidos a personas naturales y jurídicas.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'SEGUNDA: LA MUTUATARIA, es una persona natural que se dedica habitualmente a trabajo independiente.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'TERCERA: OBJETO DEL CONTRATO - Por el presente documento, EL MUTUANTE da en mutuo a favor de la MUTUATARIA y ésta recibe de aquel, la suma de dinero ascendente a S/ ${contrato.monto}, en efectivo; a su vez se obliga a devolver al MUTUANTE la referida suma de dinero en la forma y oportunidad pactadas en las cláusulas siguientes:',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'CUARTA: OBLIGACIÓN DEL MUTUANTE - EL MUTUANTE entrega a la firma del presente contrato, la suma de dinero objeto de la prestación, a LA MUTUATARIA, EN EFECTIVO, que por acuerdo de las partes cumplirá plenos efectos cancelatorios.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'QUINTA: OBLIGACIONES DE LA MUTUATARIA - LA MUTUATARIA, se obliga a recibir la suma mencionada en la cláusula anterior y devolverlo EN UNA SOLA CUOTA, por la suma de S/ ${contrato.montoPagar.toStringAsFixed(2)} el día ${contrato.fechaVencimiento.day.toString().padLeft(2, '0')}/${contrato.fechaVencimiento.month.toString().padLeft(2, '0')}/${contrato.fechaVencimiento.year}',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'SEXTA: MONEDA PACTADA - Las partes acuerdan que LA MUTUATARIA devolverá la suma de dinero objeto del mutuo, en la misma moneda y cantidad recibida, debiendo hacerlo mediante depósito bancario a favor del MUTUANTE, a la cuenta de ahorro N° 107057211001560534 de la CAJA HUANCAYO, quien canjeará el comprobante de depósito entregando las garantías prendarias indicadas en la cláusula novena.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'SÉTIMA: ONEROSIDAD DEL MUTUO - Ambas partes convienen en que el presente contrato de mutuo se celebra a título oneroso, en consecuencia, LA MUTUATARIA, está obligada al pago de intereses compensatorios a favor del MUTUANTE, de acuerdo a la tasa y forma de pago a que se refiere la cláusula siguiente:',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'OCTAVA: TASA DE INTERÉS - Queda convenido que la tasa de interés compensatoria asciende a ${contrato.interes}% mensual y por tanto equivale a S/ ${(contrato.montoPagar - contrato.monto).toStringAsFixed(2)}, la misma que está incluida en la cuota mensual a pagar, conforme al artículo quinto del presente contrato.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'NOVENA: DE LA GARANTÍA PRENDARIA-En calidad de garantía real, por la obligación de devolver el dinero mutuado a que se refiere este contrato, LA MUTUATARIA, constituye a favor del MUTUANTE, primer y preferencial prenda sobre los siguientes productos:',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Table.fromTextArray(
                    context: context,
                    cellStyle: const TextStyle(fontSize: textSize - 1),
                    cellAlignment: Alignment.centerLeft,
                    columnWidths: {
                      0: const FixedColumnWidth(110),
                      1: const FixedColumnWidth(40),
                      2: const FixedColumnWidth(40),
                      3: const FixedColumnWidth(40),
                      4: const FixedColumnWidth(40),
                      5: const FixedColumnWidth(40),
                      6: const FixedColumnWidth(40),
                    },
                    data: <List<String>>[
                      <String>[
                        'Nombre',
                        'Marca',
                        'Modelo',
                        // 'Placa',
                        'Serie',
                        'color',
                        // 'Observación',
                        'Estado',
                        // 'Precio Referencial'
                      ],
                      ...contrato.prendas
                          .map((e) => [
                                e.nombre?.toUpperCase() ?? '',
                                e.marca?.toUpperCase() ?? '',
                                e.modelo?.toUpperCase() ?? '',
                                e.serie?.toUpperCase() ?? '',
                                e.color?.toUpperCase() ?? '',
                                e.estado?.toUpperCase() ?? '',
                              ])
                          .toList()
                    ],
                  ),
                ],
              ),
            );
          }),
    );

    pdf.addPage(
      Page(
          pageFormat: PdfPageFormat.a4,
          build: (Context context) {
            return Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'DÉCIMA: La garantía prendaria descrita en la cláusula anterior se constituye con desplazamiento de los bienes al domicilio del MUTUANTE, y su vigencia se extenderá hasta la cancelación de la suma indicada en la cláusula quinta del presente documento, incluyendo intereses.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'DÉCIMO PRIMERA: Las partes dejan constancia de que la garantía prendaria comprende los bienes dados en prenda, así como sus accesorios y todo cuanto de hecho y por derecho les corresponde a los bienes prendados, sin reserva ni limitación alguna.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'DÉCIMO SEGUNDA: En caso de incumplimiento de LA MUTUATARIA en el pago de la suma a que se refiere la cláusula quinta del presente instrumento, EL MUTUANTE podrá disponer de los bienes prendados, de conformidad con el artículo 1069 del Código Civil, enajenándolos a su plena satisfacción.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'DÉCIMO TERCERO: DOMICILIOS Y JURISDICCIÓN - Las partes ratifican como sus domicilios los indicados en la introducción del presente contrato. Cualquier cambio domiciliario deberá ser comunicado a la otra parte mediante carta notarial. Para el eventual caso de divergencias, interpretación o ejecución de presente contrato, las partes se someten expresamente a la Jurisdicción y competencia de los jueces de la ciudad de Atalaya, renunciando a cualquier otro fuero, inclusive al de sus domicilios.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'DÉCIMO CUARTO: DECLARATORIO DE PROPIEDAD - El MUTUATORIO declara bajo juramento ser propietario de los bienes a la firma de este contrato según ley 27482-27444; en caso de falsedad, el MUTUATARIO acepta ser denunciado ante la ley, a las autoridades pertinentes.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'DÉCIMO QUINTO: El MUTUANTE recibe a buena fe los bienes mencionados, así como también no se hace responsable de ser falso la DECLARATORIA DE PROPIEDAD ya que el MUTUATARIO afirma Ser el propietario del BIEN a la firma de este contrato.',
                    style: const TextStyle(fontSize: textSize),
                  ),
                  // GENERAR 2 COLUMNAS PARA DOS FIRMAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: 70,
                          ),
                          Text(
                            '_________',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'FIRMA DEL CLIENTE',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            contrato.nombre,
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'DNI: ${contrato.dni}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          SizedBox(
                            height: 70,
                          ),
                          Text(
                            '_________',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'NEGOCIOS MULTIPLES MAYTA E.I.R.L.',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'JOEL MAYCO MAYTA TORRE',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'RUC: 20611213221',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  contrato.nombreAval != ''
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  height: 60,
                                ),
                                Text(
                                  '_________',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  'FIRMA DEL AVAL',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  contrato.nombreAval,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  'DNI: ${contrato.dniAval}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        )
                      : SizedBox(),
                ],
              ),
            );
          }),
    );

    return await pdf.save();
  }
}
