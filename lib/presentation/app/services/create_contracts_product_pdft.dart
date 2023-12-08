import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

abstract class CreateContractsProductPdf {
  static Future<Uint8List> crearContratoVehiculoPdf(
      Map<String, dynamic> vehiculo,
      int type,
      Map<String, dynamic> cliente) async {
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

    pdf.addPage(
      Page(
          pageFormat: PdfPageFormat.a4,
          build: (Context context) {
            final fecha = DateTime.now();
            return Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'CONTRATO PRIVADO DE COMPRA Y VENTA DE VEHICULO MENOR',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),

                  SizedBox(
                    height: 25,
                  ),
                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 10),
                      children: [
                        const TextSpan(
                            text:
                                'Consta por el presente documento de compra y venta de '),
                        TextSpan(
                          text: vehiculo['descripcion'].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ', de marca '),
                        TextSpan(
                          text: vehiculo['marca'].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ', con placa '),
                        TextSpan(
                          text: vehiculo['placa'].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                            text: ' , que celebran de una parte del Sr(a).  '),
                        TextSpan(
                          text: cliente['nombre'].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' Identificado(a) con DNI N° '),
                        TextSpan(
                          text: cliente['dni'].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                            text:
                                ' domiciliado(a) en ${cliente['domicilio']}, en lo que sigue del presente contrato será llamado EL ${type == 0 ? 'COMPRADOR' : 'VENDEDOR'} y de la otra parte la empresa '),
                        TextSpan(
                          text: 'NEGOCIOS MULTIPLES MAYTA E.I.R.L.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' con RUC '),
                        TextSpan(
                          text: '20611213221',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                            text:
                                'con domicilio fiscal CAL.URUBAMBA MZA. 8 LOTE. 8 UCAYALI - ATALAYA - RAYMONDI, quien en adelante será llamado(a) EL ${type == 0 ? 'VENDEDOR' : 'COMPRADOR'}  según las clausulas siguientes: '),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    '- PRIMERO: El VENDEDOR, declara bajo juramento ser el propietario del ${vehiculo['descripcion']} con las características Siguiente:',
                    style: const TextStyle(fontSize: 10),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  // generar lista de productos
                  Table.fromTextArray(
                    context: context,
                    cellStyle: const TextStyle(fontSize: 9),
                    cellAlignment: Alignment.centerLeft,
                    // columnWidths: {
                    //   0: const FixedColumnWidth(40),
                    //   1: const FixedColumnWidth(40),
                    //   2: const FixedColumnWidth(40),
                    //   3: const FixedColumnWidth(40),
                    //   4: const FixedColumnWidth(40),
                    //   5: const FixedColumnWidth(40),
                    // },
                    data: <List<String>>[
                      <String>[
                        'Marca',
                        'Modelo',
                        'Carroceria',
                        'Color',
                        'Motor',
                        'Serie',
                        'Placa',
                        'Año',
                      ],
                      <String>[
                        vehiculo['marca'],
                        vehiculo['modelo'],
                        vehiculo['carroceria'],
                        vehiculo['color'],
                        vehiculo['motor'],
                        vehiculo['serie'],
                        vehiculo['placa'],
                        vehiculo['anio'].toString(),
                      ],
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    '- SEGUNDO: El precio pactado por la compra venta del vehículo del que se refiere la cláusula anterior es de S/. ${cliente['valor']} pagados al contado, el vendedor declara haber recibido el monto en soles a su entera satisfacción.',
                    style: const TextStyle(fontSize: 10),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    '- TERCERO: Igualmente EL COMPRADOR a su vez declara haber recibido el(la) ${vehiculo['descripcion']} materia de este contrato a su entera satisfacción y sin responsabilidades para el vendedor en la parte técnica mecánica por ser un vehículo usado.',
                    style: const TextStyle(fontSize: 10),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      // '19 de noviembre del 2022',
                      'Atalaya, ${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  SizedBox(
                    height: 15,
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
                            cliente['nombre'].toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'DNI N° ${cliente['dni']}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            type == 0 ? 'COMPRADOR' : 'VENDEDOR',
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
                            'RUC 20611213221',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            type == 0 ? 'VENDEDOR' : 'COMPRADOR',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
    );

    return await pdf.save();
  }
}
