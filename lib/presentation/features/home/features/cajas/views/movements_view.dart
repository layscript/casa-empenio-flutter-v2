import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/validators.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/desglose_medios.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/leading_download_cajas.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/movimientos_analisis.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final list = [
  'Venta',
  'Préstamo',
  'Pago personal',
  'Pago Otros',
  'Pago',
  'Gasto',
  'Cierre de caja',
  'Aumento de préstamo',
  'Apertura de caja',
];

/// Pantalla para REVISAR los movimientos de una caja: resumen, avisos de
/// posibles errores (duplicados, datos faltantes), filtros y el detalle de
/// cada movimiento (quién, cuándo, a qué cliente y cómo se pagó).
class MovementsView extends StatefulWidget {
  const MovementsView({
    super.key,
    required this.id,
    required this.movimientos,
    required this.isClosed,
  });

  final int id;
  final List<MovimientosEntity> movimientos;
  final bool isClosed;

  @override
  State<MovementsView> createState() => _MovementsViewState();
}

class _MovementsViewState extends State<MovementsView> {
  String _sentido = 'todos'; // todos | ingresos | egresos
  ClaseMov? _clase;
  String? _medio; // etiqueta del medio (Efectivo, Yape, Depósito · BCP...)
  String? _alertaClave;
  String _busqueda = '';
  bool _nuevoPrimero = true;

  final _oCcy = NumberFormat('#,##0.00', 'en_US');
  final _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todos = widget.movimientos;
    final analisis = analizarCaja(todos);
    final vigentes = todos.where((m) => !esAnulado(m)).toList();

    var ingresos = 0.0;
    var egresos = 0.0;
    for (final m in vigentes) {
      if (esDeControl(m)) continue;
      if (m.suma == true) {
        ingresos += montoDe(m);
      } else {
        egresos += montoDe(m);
      }
    }

    // ---- filtros ----
    final idsAlerta = _alertaClave == null
        ? null
        : analisis.alertas
            .firstWhere(
              (a) => a.clave == _alertaClave,
              orElse: () => const AlertaMov(
                clave: '',
                titulo: '',
                detalle: '',
                icono: Icons.info,
                color: Colors.grey,
                ids: {},
              ),
            )
            .ids;
    final q = _busqueda.trim().toLowerCase();
    var visibles = todos.where((m) {
      if (_sentido == 'ingresos' && m.suma != true) return false;
      if (_sentido == 'egresos' && m.suma == true) return false;
      if (_clase != null && claseDe(m) != _clase) return false;
      if (_medio != null && etiquetaMedio(m) != _medio) return false;
      if (idsAlerta != null && !idsAlerta.contains(m.id)) return false;
      if (q.isNotEmpty) {
        final texto = [
          m.clienteNombre,
          m.clienteDni,
          m.observaciones,
          m.prestamoCodigo,
          m.monto,
          m.usuarioNombre,
          m.tipo?.descripcion,
        ].whereType<String>().join(' ').toLowerCase();
        if (!texto.contains(q)) return false;
      }
      return true;
    }).toList();

    visibles.sort((a, b) {
      final fa = fechaPeru(a.createdAt) ?? DateTime(2000);
      final fb = fechaPeru(b.createdAt) ?? DateTime(2000);
      return _nuevoPrimero ? fb.compareTo(fa) : fa.compareTo(fb);
    });

    // clases y medios que existen en esta caja (para mostrar solo esos filtros)
    final clases = <ClaseMov>{for (final m in todos) claseDe(m)};
    final medios = <String>{for (final m in todos) etiquetaMedio(m)};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Movimientos de Caja'),
        actions: [
          IconButton(
            tooltip: _nuevoPrimero
                ? 'Ahora: más nuevos primero'
                : 'Ahora: más antiguos primero',
            icon: Icon(
              _nuevoPrimero ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            onPressed: () => setState(() => _nuevoPrimero = !_nuevoPrimero),
          ),
          LeadingDownloadCajas(movimientos: widget.movimientos),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
        children: [
          _resumen(vigentes, ingresos, egresos),
          const SizedBox(height: 10),
          DesgloseMedios(movimientos: todos),
          const SizedBox(height: 12),
          _revision(analisis),
          const SizedBox(height: 14),
          _filtros(clases, medios),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Mostrando ${visibles.length} de ${todos.length} movimientos',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'No hay movimientos con esos filtros.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ),
            )
          else
            for (final m in visibles)
              _tarjeta(m, analisis.duplicados.contains(m.id)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- resumen
  Widget _resumen(
    List<MovimientosEntity> vigentes,
    double ingresos,
    double egresos,
  ) {
    final enMano = efectivoEnMano(widget.movimientos);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Efectivo que debe haber en caja',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'S/.${_oCcy.format(enMano)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _mini(Icons.arrow_downward, 'Entró', ingresos, Colors.greenAccent),
              const SizedBox(width: 10),
              _mini(Icons.arrow_upward, 'Salió', egresos, Colors.orangeAccent),
            ],
          ),
          Builder(builder: (_) {
            final c = cobrosDe(widget.movimientos);
            if (c.total.abs() < 0.005) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  _mini(Icons.percent, 'Intereses cobrados', c.interes,
                      Colors.lightBlueAccent),
                  const SizedBox(width: 10),
                  _mini(Icons.savings_outlined, 'Capital recuperado',
                      c.capital + c.sinDetalle, Colors.amberAccent),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          const Text(
            'No cuenta apertura/cierre ni movimientos anulados.',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _mini(IconData icono, String titulo, double valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    'S/.${_oCcy.format(valor)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- revisión
  Widget _revision(AnalisisCaja analisis) {
    if (analisis.alertas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_outlined, color: Colors.green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Todo en orden: no encontré duplicados ni datos faltantes.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: analisis.limpio ? Colors.black12 : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                analisis.limpio
                    ? Icons.info_outline
                    : Icons.warning_amber_rounded,
                color: analisis.limpio ? Colors.blueGrey : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Revisión rápida de la caja',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Toca un aviso para ver solo esos movimientos.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 8),
          for (final a in analisis.alertas)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                _alertaClave = _alertaClave == a.clave ? null : a.clave;
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: a.color.withOpacity(
                    _alertaClave == a.clave ? 0.22 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: _alertaClave == a.clave
                      ? Border.all(color: a.color, width: 1.5)
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a.icono, color: a.color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.detalle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- filtros
  Widget _filtros(Set<ClaseMov> clases, Set<String> medios) {
    Widget chip(String label, bool sel, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 6),
          child: ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: sel ? Colors.white : Colors.black87,
                fontSize: 12.5,
              ),
            ),
            selected: sel,
            selectedColor: AppColors.blue,
            onSelected: (_) => onTap(),
          ),
        );

    final ordenClases = ClaseMov.values.where(clases.contains).toList();
    final mediosOrdenados = medios.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por cliente, DNI, préstamo, monto o nota…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _busqueda.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _busqueda = '';
                      _busquedaCtrl.clear();
                    }),
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          controller: _busquedaCtrl,
          onChanged: (v) => setState(() => _busqueda = v),
        ),
        const SizedBox(height: 10),
        Wrap(
          children: [
            chip('Todos', _sentido == 'todos',
                () => setState(() => _sentido = 'todos')),
            chip('Ingresos', _sentido == 'ingresos',
                () => setState(() => _sentido = 'ingresos')),
            chip('Egresos', _sentido == 'egresos',
                () => setState(() => _sentido = 'egresos')),
          ],
        ),
        Wrap(
          children: [
            for (final c in ordenClases)
              chip(
                nombreClase(c),
                _clase == c,
                () => setState(() => _clase = _clase == c ? null : c),
              ),
          ],
        ),
        if (mediosOrdenados.length > 1)
          Wrap(
            children: [
              for (final m in mediosOrdenados)
                chip(
                  m,
                  _medio == m,
                  () => setState(() => _medio = _medio == m ? null : m),
                ),
            ],
          ),
        if (_sentido != 'todos' ||
            _clase != null ||
            _medio != null ||
            _alertaClave != null ||
            _busqueda.isNotEmpty)
          TextButton.icon(
            onPressed: () => setState(() {
              _sentido = 'todos';
              _clase = null;
              _medio = null;
              _alertaClave = null;
              _busqueda = '';
              _busquedaCtrl.clear();
            }),
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Quitar filtros'),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- tarjetas
  Widget _tarjeta(MovimientosEntity m, bool duplicado) {
    final clase = claseDe(m);
    final anulado = esAnulado(m);
    final control = esDeControl(m);
    final entra = m.suma == true;
    final color = anulado
        ? Colors.grey
        : (control
            ? Colors.blueGrey
            : (entra ? Colors.green[700]! : Colors.red[700]!));
    final f = fechaPeru(m.createdAt);
    final hora = f == null ? '-' : DateFormat('hh:mm a').format(f);
    final titulo = (m.clienteNombre ?? '').isNotEmpty
        ? m.clienteNombre!
        : nombreClase(clase);
    final detalle = [
      nombreClase(clase),
      if ((m.prestamoCodigo ?? '').isNotEmpty) 'Préstamo N° ${m.prestamoCodigo}',
    ].join(' · ');

    return Opacity(
      opacity: anulado ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: duplicado
              ? const BorderSide(color: Colors.red, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _verDetalle(m, duplicado),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.14),
                  child: Icon(iconoClase(clase), color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          decoration:
                              anulado ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        detalle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$hora · ${etiquetaMedio(m)}'
                        '${(m.usuarioNombre ?? '').isNotEmpty ? ' · ${m.usuarioNombre}' : ''}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      if (duplicado || anulado || (!esEfectivo(m) && !control))
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (duplicado)
                                _etiqueta('POSIBLE DUPLICADO', Colors.red),
                              if (anulado) _etiqueta('ANULADO', Colors.grey),
                              if (!esEfectivo(m) && !control && !anulado)
                                _etiqueta('No toca la caja', Colors.blueGrey),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${control ? '' : (entra ? '+ ' : '− ')}S/.${_oCcy.format(montoDe(m))}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: anulado ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- detalle
  void _verDetalle(MovimientosEntity m, bool duplicado) {
    final clase = claseDe(m);
    final f = fechaPeru(m.createdAt);
    final fecha =
        f == null ? '-' : DateFormat('dd/MM/yyyy  hh:mm:ss a').format(f);
    final entra = m.suma == true;

    Widget fila(String k, String? v) {
      if (v == null || v.trim().isEmpty) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                k,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(iconoClase(clase), color: AppColors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nombreClase(clase),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Text(
                      '${entra ? '+ ' : '− '}S/.${_oCcy.format(montoDe(m))}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: entra ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                if (duplicado)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _aviso(
                      Colors.red,
                      'Se parece a otro movimiento (mismo tipo, monto y '
                      'préstamo, con pocos minutos de diferencia). Si está de '
                      'más, anúlalo desde el préstamo o el gasto.',
                    ),
                  ),
                if (esAnulado(m))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _aviso(
                      Colors.blueGrey,
                      'Este movimiento fue anulado: no cuenta en el cuadre.',
                    ),
                  ),
                if (!esEfectivo(m) && !esDeControl(m) && !esAnulado(m))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _aviso(
                      Colors.blueGrey,
                      'Se hizo por ${etiquetaMedio(m)}: el dinero no entró ni '
                      'salió de la caja física, por eso no afecta el efectivo.',
                    ),
                  ),
                const Divider(height: 24),
                fila('Fecha y hora (Perú)', fecha),
                fila('Tipo', m.tipo?.descripcion),
                fila('Sentido', entra ? 'Ingreso (entró dinero)' : 'Egreso (salió dinero)'),
                fila('Medio de pago', etiquetaMedio(m)),
                fila(
                  'De lo cobrado: interés',
                  m.interesMonto == null ? null : 'S/.${_oCcy.format(m.interesMonto)}',
                ),
                fila(
                  'De lo cobrado: capital',
                  m.capitalMonto == null ? null : 'S/.${_oCcy.format(m.capitalMonto)}',
                ),
                fila('Motivo de anulación', m.motivoAnulacion),
                fila('Cliente', m.clienteNombre),
                fila('DNI', m.clienteDni),
                fila(
                  'Préstamo',
                  (m.prestamoCodigo ?? '').isNotEmpty
                      ? 'N° ${m.prestamoCodigo}'
                      : (m.prestamoId != null ? 'N° ${m.prestamoId}' : null),
                ),
                fila('Registrado por', m.usuarioNombre),
                fila('Observaciones', m.observaciones),
                fila('N° de movimiento', m.id == null ? null : '#${m.id}'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _aviso(Color color, String texto) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

class CustomChip extends StatelessWidget {
  const CustomChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final Function(bool)? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.blue[400],
    );
  }
}
