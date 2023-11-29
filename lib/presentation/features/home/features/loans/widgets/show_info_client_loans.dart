import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/full_screen_image.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class ShowInfoClientLoans extends StatefulWidget {
  const ShowInfoClientLoans({
    super.key,
    required this.nroPrestamo,
  });
  final int? nroPrestamo;

  @override
  State<ShowInfoClientLoans> createState() => _ShowInfoClientLoansState();
}

class _ShowInfoClientLoansState extends State<ShowInfoClientLoans> {
  @override
  void initState() {
    super.initState();
    if (widget.nroPrestamo != null) {
      context.read<LoansBloc>().add(GetDetailsLoan(widget.nroPrestamo!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cabeceraController = ScreenshotController();
    final bodyController = ScreenshotController();

    return AlertDialog(
      title: Screenshot(
        controller: cabeceraController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: double.infinity,
              child: Text(
                'N.M MAYTA',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Dirección: Jr. Urubamba y Jr. Iquitos',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Text(
              'Cel.: 920391631',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text(
                'Prestamo: #${widget.nroPrestamo.toString().padLeft(6, '0')}',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      content: BlocBuilder<LoansBloc, LoansState>(
        builder: (context, state) {
          final oCcy = NumberFormat("#,##0.00", "en_US");
          final loan = state.loanDetails;
          if (loan == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Screenshot(
              controller: bodyController,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 20,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${loan?.cliente?.nombres} ${loan?.cliente?.apellidos}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DNI: ${loan?.cliente?.dni}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fecha: '),
                          Text(
                            DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(
                                loan?.fecha ?? '',
                              ).toLocal(),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Plazo: '),
                          Text(
                            '${loan?.plazoDias} dia(s)',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fecha de Pago: '),
                          Text(
                            DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(
                                loan?.fechaPago ?? '',
                              ),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monto Prestado: '),
                          Text(
                            'S/. ${oCcy.format(double.parse(loan?.monto ?? '0.00'))}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Interes: '),
                          Text(
                            '(${loan?.interes}%) S/. ${oCcy.format(double.parse(loan?.ganancia ?? '0.00'))}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a Pagar: '),
                          Text(
                            oCcy.format(
                              double.parse(loan?.ganancia ?? '0.00') +
                                  double.parse(
                                    loan?.monto ?? '0.00',
                                  ),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bienes en Garantia',
                        style: TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (loan?.bienesGarantia != null)
                        ...loan!.bienesGarantia!.map((bien) {
                          return Column(
                            children: [
                              const Divider(
                                height: 20,
                                color: Colors.black,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Descripción: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${bien.description}',
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      maxLines: 4,
                                    ),
                                  )
                                ],
                              ),
                              if (bien.estado != '' && bien.estado != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Estado: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${bien.estado?.toUpperCase()}',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                              if (bien.marca != '' && bien.marca != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Marca: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${bien.marca}',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (bien.modelo != '' && bien.modelo != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Modelo: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${bien.modelo}',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (bien.color != '' && bien.color != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Color: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${bien.color}',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                              if (bien.serie != '' && bien.serie != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Serie: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${bien.serie}',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (bien.valorizacion != 0 &&
                                  bien.valorizacion != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Valorización: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        oCcy.format(bien.valorizacion),
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (bien.observaciones != '' &&
                                  bien.observaciones != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Observaciones: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${bien.observaciones}',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                              if (bien.imagen != '' && bien.imagen != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Foto: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenImage(
                                              imageUrl: bien.imagen ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        '$endPoint/${bien.imagen}.jpg',
                                        height: 50,
                                        width: 50,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ],
                          );
                        }).toList(),
                      const SizedBox(height: 20),
                      const Text(
                        'Pagos Realizados',
                        style: TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (loan?.pagos != null)
                        ...loan!.pagos!.map((pago) {
                          return Column(
                            children: [
                              const Divider(
                                height: 20,
                                color: AppColors.black,
                              ),
                              Row(
                                children: [
                                  const Text('Fecha'),
                                  Expanded(
                                    child: Text(
                                      DateFormat('dd/MM/yyyy - kk:mm').format(
                                        DateTime.parse(pago.fecha ?? '')
                                            .toLocal(),
                                      ),
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      maxLines: 4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text('Monto'),
                                  Expanded(
                                    child: Text(
                                      'S/.${oCcy.format(
                                        double.parse(pago.monto ?? '0.00'),
                                      )}',
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      maxLines: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      const Divider(
                        height: 20,
                        color: AppColors.black,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Telf: ${loan?.cliente?.celular}'),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.call,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estado: '),
                          Text('${loan?.estado}'),
                        ],
                      ),
                      if (loan?.usuario != null)
                        const Divider(
                          height: 20,
                          color: AppColors.black,
                        ),
                      if (loan?.usuario != null) const SizedBox(height: 10),
                      if (loan?.usuario != null)
                        Row(
                          children: [
                            Text(
                              'Vendedor: ${loan?.usuario?.nombre} ${loan?.usuario?.apellido}',
                            ),
                          ],
                        ),
                      if (loan?.admin != null) const SizedBox(height: 10),
                      if (loan?.admin != null)
                        Row(
                          children: [
                            Text(
                              'Editado por: ${loan?.admin?.nombre} ${loan?.admin?.apellido}',
                            ),
                          ],
                        )
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
      // TODO:: falta aqui hacer ese flujo y queda!
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                final loan = context.read<LoansBloc>().state;
                final data = loan.loanDetails;
                if (data != null) {
                  final List<PrendaEntity> prendas = [];
                  if (data.bienesGarantia != null) {
                    for (var bien in data.bienesGarantia!) {
                      final prenda = PrendaEntity(
                        nombre: bien.description,
                        marca: bien.marca,
                        modelo: bien.modelo,
                        serie: bien.serie,
                        color: bien.color,
                        estado: bien.estado,
                      );

                      prendas.add(prenda);
                    }
                  }

                  final contrato = ContratoEntity(
                    numero: data.codigo ?? 0,
                    nombre:
                        '${data.cliente?.nombres} ${data.cliente?.apellidos}',
                    dni: data.cliente?.dni ?? '',
                    domicilio: data.cliente?.domicilio ?? '',
                    fechaVencimiento: DateTime.parse(data.fechaPago ?? ''),
                    monto: double.parse(data.monto.toString()),
                    montoPagar: double.parse(data.monto.toString()) +
                        (double.parse(data.monto.toString()) *
                            double.parse(data.interes.toString()) /
                            100),
                    prendas: prendas,
                    nombreAval: data.aval == null
                        ? ''
                        : '${data.aval?.nombres} ${data.aval?.apellidos}',
                    dniAval: data.aval == null ? '' : '${data.aval?.dni}',
                    interes: double.parse(data.interes.toString()),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewPage(contrato: contrato),
                    ),
                  );
                }
              },
              child: const Text(
                'Generar Contrato',
                style: TextStyle(color: Colors.green),
              ),
            ),
            TextButton(
              onPressed: () async {
                final header = await cabeceraController.capture();
                final body = await bodyController.capture();
                if (header != null && body != null) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewScreenShotPage(
                        cabecera: header,
                        body: body,
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Capturar',
                style: TextStyle(
                  color: AppColors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        )
      ],
    );
  }
}
