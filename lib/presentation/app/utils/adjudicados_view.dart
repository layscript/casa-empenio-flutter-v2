import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Módulo "Adjudicados": todos los bienes que pasaron a venta (adjudicados) y
// si ya se vendieron o siguen por vender. Usa /adjudicacion/adjudicados.
// ---------------------------------------------------------------------------

class AdjudicadosView extends StatefulWidget {
  const AdjudicadosView({Key? key}) : super(key: key);

  @override
  State<AdjudicadosView> createState() => _AdjudicadosViewState();
}

class _AdjudicadosViewState extends State<AdjudicadosView> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: endPointPrincipal,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
  ));
  final TextEditingController _busca = TextEditingController();
  Map<String, dynamic> _datos = <String, dynamic>{};
  String _situacion = 'TODOS';
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/adjudicacion/adjudicados', queryParameters: {
        if (_busca.text.trim().isNotEmpty) 'q': _busca.text.trim(),
        'situacion': _situacion,
      });
      final d = r.data;
      _datos = Map<String, dynamic>.from((d is Map ? d['body'] : null) ?? {});
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        _error = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'Error de conexión');
      } else {
        _error = e.toString();
      }
    }
    if (mounted) setState(() => _cargando = false);
  }

  String _fecha(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '')?.toLocal();
    if (d == null) return '-';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year}';
  }

  Widget _chip(String valor, String texto, int? cantidad) {
    final sel = _situacion == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(cantidad == null ? texto : '$texto ($cantidad)'),
        selected: sel,
        onSelected: (_) {
          setState(() => _situacion = valor);
          _cargar();
        },
      ),
    );
  }

  ({String texto, Color color}) _estado(String s) {
    switch (s) {
      case 'VENDIDO':
        return (texto: 'Vendido', color: Colors.green);
      case 'PARCIAL':
        return (texto: 'Vendido con saldo pendiente', color: Colors.orange);
      default:
        return (texto: 'Por vender', color: Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ((_datos['items'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _busca,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _cargar(),
            decoration: InputDecoration(
              hintText: 'Buscar por código, DNI, cliente o bien',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward), onPressed: _cargar),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            _chip('TODOS', 'Todos', _datos['total'] as int?),
            _chip('POR_VENDER', 'Por vender', _datos['porVender'] as int?),
            _chip('VENDIDO', 'Vendidos', _datos['vendidos'] as int?),
            _chip('PARCIAL', 'Con saldo', _datos['parciales'] as int?),
          ]),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red))))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: items.isEmpty
                          ? ListView(children: const [
                              Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Text(
                                      'No hay bienes adjudicados con ese filtro.',
                                      textAlign: TextAlign.center))
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 30),
                              itemCount: items.length,
                              itemBuilder: (_, i) => _tarjeta(items[i]),
                            ),
                    ),
        ),
      ],
    );
  }

  Widget _tarjeta(Map<String, dynamic> it) {
    final est = _estado((it['situacion'] ?? '').toString());
    final bienes = ((it['bienes'] as List?) ?? const []).join(', ');
    final venta = it['venta'] as Map?;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                    'Préstamo ${it['prestamoCodigo']}  ·  ${it['cliente'] ?? ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: est.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(est.texto,
                    style: TextStyle(
                        color: est.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(bienes.isEmpty ? 'Sin descripción del bien' : bienes),
            const SizedBox(height: 4),
            Text(
              'Prestado S/. ${(it['monto'] as num?)?.toStringAsFixed(2) ?? '-'}'
              '  ·  Venció: ${_fecha(it['vencimiento'])}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              it['porProceso'] == true
                  ? 'Adjudicado el ${_fecha(it['adjudicadoAt'])} '
                      '(${it['adjudicadoPor'] == 'SISTEMA' ? 'automático' : 'por el cajero'})'
                  : 'Adjudicación anterior al nuevo proceso',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (venta != null)
              Text(
                'Venta ${venta['cod'] ?? venta['id']} · S/. ${venta['total'] ?? '-'} · ${_fecha(venta['fecha'])}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}
