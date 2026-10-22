import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/tareas_cobranza_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Panel de control de Préstamos: lo primero que ves al entrar.
/// Muestra cuánto dinero hay en la calle, qué préstamos ya vencieron o están
/// por vencer (con botones de llamar / WhatsApp) y lo prestado/cobrado hoy.
class PanelPrestamos extends StatefulWidget {
  const PanelPrestamos({super.key, required this.onAbrirCliente});

  /// Se llama con el DNI del cliente para abrir sus préstamos.
  final void Function(String dni) onAbrirCliente;

  @override
  State<PanelPrestamos> createState() => PanelPrestamosState();
}

class PanelPrestamosState extends State<PanelPrestamos> {
  Map<String, dynamic>? _data;
  bool _cargando = true;
  String? _error;
  final _oCcy = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final repo = context.read<LoansRepository>();
    final suc = context.read<Preferences>().token?.sucursal?.id ?? 1;
    final r = await repo.getPanel(sucursalId: suc);
    if (!mounted) return;
    r.fold(
      (e) => setState(() {
        _error = e;
        _cargando = false;
      }),
      (d) => setState(() {
        _data = d;
        _cargando = false;
      }),
    );
  }

  double _n(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
  String _s(dynamic v) => 'S/.${_oCcy.format(_n(v))}';

  Future<void> _llamar(String? cel) async {
    if (cel == null || cel.trim().isEmpty) return;
    await launchUrl(Uri.parse('tel:${cel.trim()}'));
  }

  Future<void> _whatsapp(Map<String, dynamic> f, bool vencido) async {
    final cel = (f['celular'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    if (cel.isEmpty) return;
    final numero = cel.length == 9 ? '51$cel' : cel;
    final nombre = (f['cliente'] ?? '').toString();
    final codigo = (f['codigoFormateado'] ?? f['codigo']).toString();
    final msg = vencido
        ? 'Hola $nombre, le saludamos de Negocios Múltiples Mayta. Su préstamo N° $codigo '
            'ya venció y tiene un saldo de ${_s(f['saldo'])}. Por favor acérquese a regularizar su pago. Gracias.'
        : 'Hola $nombre, le saludamos de Negocios Múltiples Mayta. Le recordamos que su '
            'préstamo N° $codigo está por vencer. Saldo: ${_s(f['saldo'])}. Lo esperamos. Gracias.';
    await launchUrl(
      Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(msg)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _data == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_error ?? 'No se pudo cargar el panel'),
            TextButton.icon(
              onPressed: cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final d = _data!;
    final venc = (d['vencidos'] as List? ?? []).cast<Map<String, dynamic>>();
    final porV = (d['porVencer'] as List? ?? []).cast<Map<String, dynamic>>();
    final medios = (d['cobradoPorMedio'] as Map? ?? {});

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Panel de control',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              IconButton(
                tooltip: 'Cobranza y adjudicación',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TareasCobranzaPage(),
                  ),
                ),
                icon: const Icon(Icons.gavel, color: Colors.orange),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: cargar,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Row(
            children: [
              _Tarjeta(
                icono: Icons.account_balance_wallet_outlined,
                titulo: 'Dinero en la calle',
                valor: _s(d['capitalCalle']),
                sub: '${d['abiertos']} préstamos abiertos',
                color: AppColors.blue,
              ),
              const SizedBox(width: 8),
              _Tarjeta(
                icono: Icons.savings_outlined,
                titulo: 'Por cobrar',
                valor: _s(d['saldoPorCobrar']),
                sub: 'capital + interés pendiente',
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Tarjeta(
                icono: Icons.warning_amber_rounded,
                titulo: 'Vencidos',
                valor: '${d['vencidosTotal']}',
                sub: 'pasó su fecha de pago',
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _Tarjeta(
                icono: Icons.schedule,
                titulo: 'Por vencer (3 días)',
                valor: '${d['porVencerTotal']}',
                sub: 'avísales a tiempo',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hoy',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _Linea('Prestado (${d['prestamosHoy']})', _s(d['prestadoHoy']),
                    Colors.red[700]!),
                _Linea('Cobrado (${d['pagosHoy']})', _s(d['cobradoHoy']),
                    Colors.green[700]!),
                for (final e in medios.entries)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: _Linea(
                      '· ${_nombreMedio('${e.key}')}',
                      _s(e.value),
                      AppColors.secondaryText,
                      chico: true,
                    ),
                  ),
              ],
            ),
          ),
          if (venc.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Titulo('⚠ Vencidos: cobra primero a estos', Colors.red[700]!),
            for (final f in venc) _fila(f, true),
          ],
          if (porV.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Titulo('⏰ Por vencer en 3 días', Colors.orange[800]!),
            for (final f in porV) _fila(f, false),
          ],
          if (venc.isEmpty && porV.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text('🎉 No hay préstamos vencidos ni por vencer.'),
            ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }

  String _nombreMedio(String m) {
    switch (m) {
      case 'DEPOSITO':
        return 'Depósito';
      case 'YAPE':
        return 'Yape';
      case 'PLIN':
        return 'Plin';
      case 'OTRO':
        return 'Otro';
      default:
        return 'Efectivo';
    }
  }

  Widget _fila(Map<String, dynamic> f, bool vencido) {
    final dias = (f['dias'] as num?)?.toInt() ?? 0;
    final texto = vencido
        ? 'Venció hace ${dias.abs()} día${dias.abs() == 1 ? '' : 's'}'
        : (dias == 0 ? 'Vence HOY' : 'Vence en $dias día${dias == 1 ? '' : 's'}');
    final color = vencido ? Colors.red : Colors.orange;
    final reno = (f['renovaciones'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => widget.onAbrirCliente('${f['dni'] ?? ''}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${f['cliente']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'N° ${f['codigoFormateado'] ?? f['codigo']} · saldo ${_s(f['saldo'])}'
                      '${reno > 0 ? ' · renovado $reno×' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(texto,
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Llamar',
              onPressed: () => _llamar(f['celular']?.toString()),
              icon: const Icon(Icons.call, color: Colors.blue),
            ),
            IconButton(
              tooltip: 'WhatsApp',
              onPressed: () => _whatsapp(f, vencido),
              icon: const Icon(Icons.chat, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.t, this.c);
  final String t;
  final Color c;
  @override
  Widget build(BuildContext context) => Text(
        t,
        style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 15),
      );
}

class _Linea extends StatelessWidget {
  const _Linea(this.a, this.b, this.c, {this.chico = false});
  final String a;
  final String b;
  final Color c;
  final bool chico;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
                child: Text(a, style: TextStyle(fontSize: chico ? 12 : 14))),
            Text(b,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c,
                    fontSize: chico ? 12 : 14)),
          ],
        ),
      );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.sub,
    required this.color,
  });
  final IconData icono;
  final String titulo;
  final String valor;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color),
            const SizedBox(height: 4),
            Text(titulo, style: const TextStyle(fontSize: 12)),
            Text(valor,
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold, color: color)),
            Text(sub,
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }
}
