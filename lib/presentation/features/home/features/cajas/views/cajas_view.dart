import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/movements_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CajasView extends StatefulWidget {
  const CajasView({super.key});

  @override
  State<CajasView> createState() => _CajasViewState();
}

class _CajasViewState extends State<CajasView> {
  String _filtro = 'Todas';

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0.00", "en_US");

    return BlocProvider(
      lazy: false,
      create: (context) => CajasBloc(
        cajaRepository: context.read(),
        expensesRepository: context.read(),
        preferences: context.read(),
      )..add(GetAllCajas()),
      child: Builder(builder: (context) {
        return BlocBuilder<CajasBloc, CajasState>(
          builder: (context, state) {
            switch (state.cajasStatus) {
              case CajasStatus.initial || CajasStatus.loading:
                return const ButtonStateLoading();

              case CajasStatus.error || CajasStatus.failure:
                return ButtonStateError(
                  onPressed: () {
                    context.read<CajasBloc>().add(GetAllCajas());
                  },
                );

              case CajasStatus.loaded || CajasStatus.success:
                final cajaBloc = context.read<CajasBloc>();
                final todas = state.listCajas ?? [];

                // Diferencia = lo contado - lo que debía haber (0 = caja cuadrada)
                double difDe(dynamic caja) {
                  if (caja == null) return 0;
                  final d = double.tryParse(caja.montoDiferencia ?? '0') ?? 0;
                  return d != 0 ? d * -1 : 0;
                }

                final cuadradas = todas.where((c) => difDe(c) == 0).length;
                final conDif = todas.length - cuadradas;
                final lista = todas.where((c) {
                  final d = difDe(c);
                  if (_filtro == 'Cuadradas') return d == 0;
                  if (_filtro == 'Con diferencia') return d != 0;
                  return true;
                }).toList();

                return SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Lista de Cajas (cerradas)',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ---- Guía didáctica ----
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: Colors.blue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Aquí ves el historial de cajas ya cerradas. '
                                  'Verde = la caja cuadró exacto. Rojo = hubo '
                                  'diferencia (faltó o sobró dinero). Toca una '
                                  'caja para ver el detalle.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ---- Resumen ----
                        Row(
                          children: [
                            _Resumen(
                              icono: Icons.inventory_2_outlined,
                              titulo: 'Cajas',
                              valor: '${todas.length}',
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 8),
                            _Resumen(
                              icono: Icons.check_circle_outline,
                              titulo: 'Cuadradas',
                              valor: '$cuadradas',
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _Resumen(
                              icono: Icons.warning_amber_rounded,
                              titulo: 'Con diferencia',
                              valor: '$conDif',
                              color: Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final f in const [
                              'Todas',
                              'Cuadradas',
                              'Con diferencia'
                            ])
                              ChoiceChip(
                                label: Text(f),
                                selected: _filtro == f,
                                onSelected: (_) => setState(() => _filtro = f),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (lista.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(30),
                            child: Text('No hay cajas para mostrar.'),
                          ),
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          shrinkWrap: true,
                          itemCount: lista.length,
                          itemBuilder: (context, index) {
                            final caja = lista[index];
                            final valor = difDe(caja);
                            final cuadra = valor == 0;
                            final color = cuadra ? Colors.green : Colors.red;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ExpansionTile(
                                  backgroundColor: color.withOpacity(0.06),
                                  collapsedBackgroundColor:
                                      color.withOpacity(0.06),
                                  leading: CircleAvatar(
                                    backgroundColor: color.withOpacity(0.15),
                                    child: Icon(
                                      cuadra
                                          ? Icons.check_circle
                                          : Icons.error_outline,
                                      color: color,
                                    ),
                                  ),
                                  title: Text(
                                    'Caja N°: ${caja?.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    //'Fecha: ${DateFormat('dd/MM/yyyy - hh:mm').format(DateTime.parse(caja?.createdAt ?? '').toLocal())}',
                                    '${caja?.fecha ?? ''}  ·  ${caja?.estado}\n'
                                    '${cuadra ? 'Cuadró exacto' : (valor < 0 ? 'Faltó dinero' : 'Sobró dinero')}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Diferencia',
                                          style: TextStyle(fontSize: 11)),
                                      Text(
                                        'S/.${oCcy.format(valor)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ).copyWith(bottom: 16),
                                  children: [
                                    if (caja?.estado != 'Abierta') ...[
                                      _Fila('Monto de Apertura',
                                          'S/.${caja?.montoApertura}'),
                                      _Fila('Usuario de Apertura',
                                          caja?.usuarioApertura?.fullName ?? ''),
                                      _Fila('Usuario de Cierre',
                                          caja?.usuarioCierre?.fullName ?? ''),
                                      _Fila('Fecha y Hora de Apertura',
                                          '${caja?.fecha} / ${setTimeToLocal(caja?.horaApertura ?? '')}'),
                                      _Fila('Hora de Cierre',
                                          setTimeToLocal(caja?.horaCierre ?? '')),
                                      const Divider(),
                                      _Fila('Total Ingresos (+)',
                                          caja?.totalIngresos ?? '',
                                          color: Colors.green[800]),
                                      _Fila('Total Egresos (−)',
                                          caja?.totalEgresos ?? '',
                                          color: Colors.red[800]),
                                      _Fila('Monto de Cierre Teórico',
                                          'S/.${caja?.montoCierreTeorico}',
                                          ayuda: 'Lo que DEBÍA haber en caja'),
                                      _Fila('Monto de Cierre Real',
                                          'S/.${caja?.montoCierreReal}',
                                          ayuda: 'Lo que se contó al cerrar'),
                                      _Fila('Diferencia',
                                          'S/.${oCcy.format(valor)}',
                                          color: color, negrita: true),
                                      if ((caja?.observaciones ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        _Fila('Observaciones',
                                            '${caja?.observaciones}'),
                                      const SizedBox(height: 6),
                                    ],
                                    if (caja != null &&
                                        caja.movimientos!.isNotEmpty)
                                      SecondaryButton(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return BlocProvider.value(
                                                  value: cajaBloc,
                                                  child: MovementsView(
                                                    movimientos:
                                                        caja.movimientos ?? [],
                                                    id: caja.id ?? 0,
                                                    isClosed: true,
                                                  ),
                                                );
                                              },
                                            ),
                                          );

                                          if (mounted) {
                                            context.read<CajasBloc>().add(
                                                  GetAllCajas(),
                                                );
                                          }
                                        },
                                        child: Text(
                                          'Ver Movimientos (${caja.movimientos?.length})',
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
            }
          },
        );
      }),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
  });
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icono, color: color),
            Text(valor,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor,
      {this.color, this.negrita = false, this.ayuda});
  final String etiqueta;
  final String valor;
  final Color? color;
  final bool negrita;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (ayuda != null)
                  Text(ayuda!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
