import 'package:casa_empenio_pe/domain/contract/contract_entity.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowDetailsReportLoans extends StatefulWidget {
  const ShowDetailsReportLoans({
    super.key,
    required this.nroPrestamo,
  });
  final int? nroPrestamo;

  @override
  State<ShowDetailsReportLoans> createState() => _ShowDetailsReportLoansState();
}

class _ShowDetailsReportLoansState extends State<ShowDetailsReportLoans> {
  @override
  void initState() {
    super.initState();
    if (widget.nroPrestamo != null) {
      context
          .read<ReportsBloc>()
          .add(GetDetailsReportLoan(widget.nroPrestamo!));
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
                'N.M. MAYTA',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text('Direccion: Jr. Urubamba y Jr. Iquitos',
                style: TextStyle(fontSize: 16)),
            const Text(
              'Cel.: 920391631',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text(
                'Prestamo: #${widget.nroPrestamo.toString().padLeft(6, '0')}',
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
      content: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state.isReportsDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state.isReportsDetailsError) {
            return const Center(
              child: Text('Ocurrió un error, intentelo de nuevo'),
            );
          } else if (state.isReportsDetailsSuccess &&
              state.loanDetails != null) {
            final prestamo = state.loanDetails!;
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
                            '${prestamo.cliente?.nombres} ${prestamo.cliente?.apellidos}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DNI: ${prestamo.cliente?.dni}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Fecha: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(prestamo.fecha ?? '').toLocal()))
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Plazo: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${prestamo.plazoDias} dia(s)')
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Fecha de Pago: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(prestamo.fechaPago ?? '')))
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Monto Prestado: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              'S/.${oCcy.format(double.parse(prestamo.monto.toString()))}')
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Interes: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              "(${prestamo.interes}%) S/.${oCcy.format(double.parse(prestamo.ganancia ?? '0.00'))}")
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total a Pagar: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              'S/.${oCcy.format(double.parse(prestamo.ganancia ?? '0.00') + double.parse(prestamo.monto ?? '0.00'))}')
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        "Bienes en Garantia",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (prestamo.bienesGarantia != null)
                        ...prestamo.bienesGarantia!.map<Widget>((prenda) {
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
                                      prenda.description ?? '',
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      maxLines: 4,
                                    ),
                                  )
                                ],
                              ),
                              if (prenda.estado != '' &&
                                  prenda.estado != null) ...[
                                const SizedBox(height: 10),
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
                                        prenda.estado?.toUpperCase() ?? '',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (prenda.marca != '' &&
                                  prenda.marca != null) ...[
                                const SizedBox(height: 10),
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
                                        prenda.marca ?? '',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (prenda.modelo != '' &&
                                  prenda.modelo != null) ...[
                                const SizedBox(height: 10),
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
                                        prenda.modelo ?? '',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (prenda.color != '' &&
                                  prenda.color != null) ...[
                                const SizedBox(height: 10),
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
                                        prenda.color ?? '',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (prenda.serie != '' &&
                                  prenda.serie != null) ...[
                                const SizedBox(height: 10),
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
                                        prenda.serie ?? '',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (prenda.valorizacion != 0 &&
                                  prenda.valorizacion != null) ...[
                                const SizedBox(height: 10),
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
                                        oCcy.format(prenda.valorizacion),
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                              if (prenda.observaciones != '' &&
                                  prenda.observaciones != null) ...[
                                const SizedBox(height: 10),
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
                                        prenda.observaciones ?? '',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                )
                              ],
                              if (prenda.imagen != '' &&
                                  prenda.imagen != null) ...[
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
                                              imageUrl: prenda.imagen ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        '$endPointPrincipal/${prenda.imagen}.jpg',
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
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        "Pagos Realizados",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (prestamo.pagos != null)
                        ...prestamo.pagos!.map<Widget>((pago) {
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
                                    "Fecha: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      DateFormat('dd/MM/yyyy - kk:mm').format(
                                          DateTime.parse(pago.fecha ?? '')
                                              .toLocal()),
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      maxLines: 4,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Monto: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'S/.${oCcy.format(double.parse(pago.monto ?? '0.00'))}',
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      maxLines: 4,
                                    ),
                                  )
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      const Divider(
                        height: 20,
                        color: Colors.black,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Telf: ${prestamo.cliente?.celular}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call),
                            color: Colors.green,
                            onPressed: () async {
                              final phone = prestamo.cliente?.celular;
                              await customLaunchUrl(
                                Uri(
                                  scheme: 'tel',
                                  path: phone,
                                ),
                              );
                            },
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Estado: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(prestamo.estado ?? '')
                        ],
                      ),
                      prestamo.usuario != null
                          ? const Divider(
                              height: 20,
                              color: Colors.black,
                            )
                          : const SizedBox(),
                      prestamo.usuario != null
                          ? const SizedBox(
                              height: 10,
                            )
                          : const SizedBox(),
                      prestamo.usuario != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Vendedor: ${prestamo.usuario?.nombre} ${prestamo.usuario?.apellido}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : const SizedBox(),
                      prestamo.admin != null
                          ? const SizedBox(
                              height: 10,
                            )
                          : const SizedBox(),
                      prestamo.admin != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Editado por: ${prestamo.admin?.nombre} ${prestamo.admin?.apellido}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text(
                'Generar Contrato',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                final loan = context.read<ReportsBloc>().state;
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
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text(
                'Capturar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                final cabecera = await cabeceraController.capture();
                final body = await bodyController.capture();

                if (!mounted) return;

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreenShotPage(
                        cabecera: cabecera!, body: body!),
                  ),
                );
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text(
                'Aceptar',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        )
      ],
    );
  }
}
