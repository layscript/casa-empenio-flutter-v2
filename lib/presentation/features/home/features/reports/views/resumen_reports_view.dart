import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Resumen del negocio por periodo (hora de Perú): cuánto se prestó, cuánto se
/// cobró, por qué medio y cómo va cada día.
class ResumenReportsView extends StatefulWidget {
  const ResumenReportsView({super.key});

  @override
  State<ResumenReportsView> createState() => _ResumenReportsViewState();
}

class _ResumenReportsViewState extends State<ResumenReportsView> {
  final _oCcy = NumberFormat('#,##0.00', 'en_US');
  String _rango = 'Hoy';
  DateTimeRange? _custom;
  Map<String, dynamic>? _data;
  bool _cargando = true;
  String? _error;

  static const _rangos = ['Hoy', 'Ayer', '7 días', 'Este mes', 'Mes pasado', 'Otro'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Día de Perú (UTC-5) -> instante UTC real de las 00:00 de ese día
  DateTime _inicioDia(int y, int m, int d) =>
      DateTime.utc(y, m, d).add(const Duration(hours: 5));

  (DateTime, DateTime, String) _periodo() {
    final p = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    DateTime ini;
    DateTime fin;
    switch (_rango) {
      case 'Ayer':
        ini = _inicioDia(p.year, p.month, p.day - 1);
        fin = _inicioDia(p.year, p.month, p.day);
        break;
      case '7 días':
        ini = _inicioDia(p.year, p.month, p.day - 6);
        fin = _inicioDia(p.year, p.month, p.day + 1);
        break;
      case 'Este mes':
        ini = _inicioDia(p.year, p.month, 1);
        fin = _inicioDia(p.year, p.month, p.day + 1);
        break;
      case 'Mes pasado':
        ini = _inicioDia(p.year, p.month - 1, 1);
        fin = _inicioDia(p.year, p.month, 1);
        break;
      case 'Otro':
        final r = _custom ??
            DateTimeRange(start: DateTime.now(), end: DateTime.now());
        ini = _inicioDia(r.start.year, r.start.month, r.start.day);
        fin = _inicioDia(r.end.year, r.end.month, r.end.day + 1);
        break;
      default:
        ini = _inicioDia(p.year, p.month, p.day);
        fin = _inicioDia(p.year, p.month, p.day + 1);
    }
    final finInclusivo = fin.subtract(const Duration(seconds: 1));
    final f = DateFormat('dd/MM/yyyy');
    final a = ini.subtract(const Duration(hours: 5));
    final b = finInclusivo.subtract(const Duration(hours: 5));
    final etiqueta = f.format(a) == f.format(b)
        ? f.format(a)
        : '${f.format(a)} al ${f.format(b)}';
    return (ini, finInclusivo, etiqueta);
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final (ini, fin, _) = _periodo();
    final suc = context.read<Preferences>().token?.sucursal?.id ?? 1;
    final r = await context
        .read<LoansRepository>()
        .getResumenPeriodo(inicio: ini, fin: fin, sucursalId: suc);
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

  Future<void> _compartir(String etiqueta) async {
    final d = _data;
    if (d == null) return;
    final medios = (d['porMedio'] as Map? ?? {});
    final b = StringBuffer()
      ..writeln('📊 Resumen $etiqueta')
      ..writeln('Negocios Múltiples Mayta')
      ..writeln('')
      ..writeln('💸 Prestado: ${_s(d['prestado'])} (${d['prestamosNuevos']} préstamos)')
      ..writeln('💰 Cobrado: ${_s(d['cobrado'])} (${d['pagos']} pagos)')
      ..writeln('🔁 Renovaciones: ${d['renovaciones']}')
      ..writeln('✅ Liquidaciones: ${d['liquidaciones']}');
    for (final e in medios.entries) {
      b.writeln('   · ${e.key}: ${_s(e.value)}');
    }
    await launchUrl(
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(b.toString())}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = _periodo().$3;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const Text(
            'Aquí ves cómo va el negocio: cuánto prestaste, cuánto cobraste y por qué medio te pagaron.',
            style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final r in _rangos)
                ChoiceChip(
                  label: Text(r),
                  selected: _rango == r,
                  onSelected: (_) async {
                    if (r == 'Otro') {
                      final x = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2022, 1, 1),
                        lastDate: DateTime(2035, 12, 31),
                      );
                      if (x == null) return;
                      _custom = x;
                    }
                    setState(() => _rango = r);
                    _cargar();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('📅 $etiqueta',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null || _data == null)
            Center(
              child: Column(
                children: [
                  Text(_error ?? 'Error'),
                  TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                ],
              ),
            )
          else
            ..._contenido(etiqueta),
        ],
      ),
    );
  }

  List<Widget> _contenido(String etiqueta) {
    final d = _data!;
    final prestado = _n(d['prestado']);
    final cobrado = _n(d['cobrado']);
    final neto = cobrado - prestado;
    final medios = Map<String, dynamic>.from(d['porMedio'] as Map? ?? {});
    final serie = (d['serie'] as List? ?? []).cast<Map<String, dynamic>>();
    final entradas = medios.entries.toList()
      ..sort((a, b) => _n(b.value).compareTo(_n(a.value)));

    return [
      Row(
        children: [
          _Kpi('💸 Prestado', _s(prestado), '${d['prestamosNuevos']} préstamos',
              Colors.red),
          const SizedBox(width: 8),
          _Kpi('💰 Cobrado', _s(cobrado), '${d['pagos']} pagos', Colors.green),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (neto >= 0 ? Colors.green : Colors.red).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Flujo neto del periodo'),
            Text(
              '${neto >= 0 ? '+' : '-'}${_s(neto.abs())}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: neto >= 0 ? Colors.green[800] : Colors.red[800],
              ),
            ),
            Text(
              neto >= 0
                  ? 'Entró más dinero del que salió en préstamos.'
                  : 'Prestaste más de lo que cobraste (normal si estás colocando capital).',
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _Mini('🔁 Renovaciones', '${d['renovaciones']}'),
          const SizedBox(width: 8),
          _Mini('✅ Liquidaciones', '${d['liquidaciones']}'),
        ],
      ),
      const SizedBox(height: 14),
      const Text('¿Cómo te pagaron?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 6),
      if (entradas.isEmpty) const Text('Sin cobros en este periodo.'),
      for (final e in entradas)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_nombre(e.key))),
                  Text(_s(e.value),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: cobrado == 0 ? 0 : (_n(e.value) / cobrado).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: Colors.black12,
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 14),
      if (serie.length > 1) ...[
        const Text('Día por día',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const Row(
          children: [
            Icon(Icons.square, size: 12, color: Colors.red),
            Text(' Prestado   ', style: TextStyle(fontSize: 11)),
            Icon(Icons.square, size: 12, color: Colors.green),
            Text(' Cobrado', style: TextStyle(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        _Grafico(serie: serie),
        const SizedBox(height: 14),
      ],
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _compartir(etiqueta),
          icon: const Icon(Icons.share),
          label: const Text('Compartir resumen por WhatsApp'),
        ),
      ),
    ];
  }

  String _nombre(String k) {
    final partes = k.split(' · ');
    final base = partes.first;
    final n = {
      'EFECTIVO': '💵 Efectivo',
      'DEPOSITO': '🏦 Depósito',
      'YAPE': '📱 Yape',
      'PLIN': '📱 Plin',
      'OTRO': '➕ Otro',
    }[base];
    return n == null ? k : (partes.length > 1 ? '$n · ${partes[1]}' : n);
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.t, this.v, this.s, this.c);
  final String t;
  final String v;
  final String s;
  final Color c;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: const TextStyle(fontSize: 12)),
              Text(v,
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold, color: c)),
              Text(s,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.secondaryText)),
            ],
          ),
        ),
      );
}

class _Mini extends StatelessWidget {
  const _Mini(this.t, this.v);
  final String t;
  final String v;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
              Text(v,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
        ),
      );
}

class _Grafico extends StatelessWidget {
  const _Grafico({required this.serie});
  final List<Map<String, dynamic>> serie;

  double _n(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    var max = 1.0;
    for (final s in serie) {
      final a = _n(s['prestado']);
      final b = _n(s['cobrado']);
      if (a > max) max = a;
      if (b > max) max = b;
    }
    const alto = 130.0;
    return SizedBox(
      height: alto + 26,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final s in serie)
            Container(
              width: 38,
              margin: const EdgeInsets.only(right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: alto,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 11,
                          height: (_n(s['prestado']) / max) * alto,
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 11,
                          height: (_n(s['cobrado']) / max) * alto,
                          decoration: BoxDecoration(
                            color: Colors.green[500],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(s['fecha'] as String).substring(8)}/${(s['fecha'] as String).substring(5, 7)}',
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
