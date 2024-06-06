import 'package:cached_network_image/cached_network_image.dart';
import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/config/config.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
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
    final authPreferences = context.read<Preferences>().token;
    final cabeceraController = ScreenshotController();
    final bodyController = ScreenshotController();

    final nombreSucursal = authPreferences?.sucursal?.nombre;
    final direccionSucursal = authPreferences?.sucursal?.direccion;
    final telefonoSucursal = authPreferences?.sucursal?.telefono;
    final extrasSucursal = authPreferences?.sucursal?.extras;

    return AlertDialog(
      title: Screenshot(
        controller: cabeceraController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                nombreSucursal ?? 'N.M MAYTA',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              direccionSucursal ?? 'Dirección: Jr. Urubamba y Jr. Iquitos',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            Text(
              'Cel.: ${telefonoSucursal ?? '920391631'}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            if (extrasSucursal != null)
              Text(
                'Extra.: $extrasSucursal',
                style: const TextStyle(
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

          if (loan == null && state.error == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (loan == null && state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: const TextStyle(
                  color: AppColors.red,
                ),
              ),
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
                        children: [
                          Expanded(
                            child: Text(
                              '${loan?.cliente?.nombres} ${loan?.cliente?.apellidos}',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (loan?.cliente?.imagenUno != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImage(
                                        imageUrl:
                                            loan?.cliente?.imagenUno ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  '$endPointPrincipal/${loan?.cliente?.imagenUno}',
                                  width: 60,
                                  height: 60,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Placeholder(
                                      fallbackHeight: 60,
                                      fallbackWidth: 60,
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                AppIcons.notFound,
                                width: 60,
                                height: 60,
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
                      const SizedBox(height: 10),
                      if (loan?.imagenLiquidado != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Foto de Liquidación: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImage(
                                      imageUrl: loan?.imagenLiquidado ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Image.network(
                                '$endPointPrincipal/${loan?.imagenLiquidado}',
                                height: 50,
                                width: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Placeholder(
                                    fallbackHeight: 50,
                                    fallbackWidth: 50,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (loan?.imagenPagos != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Foto del Pago: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImage(
                                      imageUrl: loan?.imagenPagos ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Image.network(
                                '$endPointPrincipal/${loan?.imagenPagos}',
                                height: 50,
                                width: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Placeholder(
                                    fallbackHeight: 50,
                                    fallbackWidth: 50,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (loan?.imagenAumentos != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Foto del Aumento: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImage(
                                      imageUrl: loan?.imagenAumentos ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Image.network(
                                '$endPointPrincipal/${loan?.imagenAumentos}',
                                height: 50,
                                width: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Placeholder(
                                    fallbackHeight: 50,
                                    fallbackWidth: 50,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Aumentos (${loan?.aumentos?.length ?? '0'})',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (loan?.aumentos != null)
                        ...loan!.aumentos!.map((aumento) {
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
                                      DateFormat('dd/MM/yyyy - hh:mm').format(
                                          DateTime.parse(aumento.fecha ?? '')
                                              .toLocal()),
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Monto: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      's/.${aumento.monto}',
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Observaciones: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${aumento.observaciones}',
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      const SizedBox(height: 20),
                      Text(
                        'Bienes en Garantia (${loan?.bienesGarantia?.length})',
                        style: const TextStyle(
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
                                        '${bien.estado?.toUpperCase()}',
                                        overflow: TextOverflow.clip,
                                        textAlign: TextAlign.end,
                                        maxLines: 4,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                              if (bien.categoria != '' &&
                                  bien.categoria != null) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Categoria: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${bien.categoria?.toUpperCase()}',
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
                                      "Imagen 1: ",
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
                                      // TODO:: Revisar bien csmre:v
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '$endPointPrincipal/${bien.imagen}',
                                        height: 50,
                                        width: 50,
                                        placeholder: (context, url) {
                                          return const Placeholder(
                                            fallbackHeight: 50,
                                            fallbackWidth: 50,
                                          );
                                        },
                                        errorWidget: (context, url, error) {
                                          return const Placeholder(
                                            fallbackHeight: 50,
                                            fallbackWidth: 50,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              ],
                              if (bien.imagenDos != '' &&
                                  bien.imagenDos != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Imagen 2: ",
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
                                              imageUrl: bien.imagenDos ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      // TODO:: Revisar bien csmre:v
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '$endPointPrincipal/${bien.imagenDos}',
                                        height: 50,
                                        width: 50,
                                        placeholder: (context, url) {
                                          return const Placeholder(
                                            fallbackHeight: 50,
                                            fallbackWidth: 50,
                                          );
                                        },
                                        errorWidget: (context, url, error) {
                                          return const Placeholder(
                                            fallbackHeight: 50,
                                            fallbackWidth: 50,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              ],
                              if (bien.imagenTres != '' &&
                                  bien.imagenTres != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Imagen 3: ",
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
                                              imageUrl: bien.imagenTres ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '$endPointPrincipal/${bien.imagenTres}',
                                        height: 50,
                                        width: 50,
                                        placeholder: (context, url) {
                                          return const Placeholder(
                                            fallbackHeight: 50,
                                            fallbackWidth: 50,
                                          );
                                        },
                                        errorWidget: (context, url, error) {
                                          return const Placeholder(
                                            fallbackHeight: 50,
                                            fallbackWidth: 50,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ],
                          );
                        }).toList(),
                      const SizedBox(height: 20),
                      Text(
                        'Pagos Realizados (${loan?.pagos?.length})',
                        style: const TextStyle(
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
                            onPressed: () async {
                              final phone = loan?.cliente?.celular;
                              await customLaunchUrl(
                                Uri(
                                  scheme: 'tel',
                                  path: phone,
                                ),
                              );
                            },
                            icon: const Icon(
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
                      if (loan?.estado == 'LIQUIDADO') ...[
                        const SizedBox(height: 10),
                        if (loan?.imagenLiquidado != null)
                          Image.network(
                            '$endPointPrincipal/${loan!.imagenLiquidado}',
                            height: 100,
                            width: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return const Placeholder(
                                fallbackHeight: 50,
                                fallbackWidth: 50,
                              );
                            },
                          ),
                      ],
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
