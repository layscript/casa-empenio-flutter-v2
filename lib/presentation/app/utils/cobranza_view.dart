import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

final Dio _dio = Dio(BaseOptions(
  baseUrl: endPointPrincipal,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 90),
));

dynamic _cuerpo(Response<dynamic> r) {
  try {
    final d = r.data is String ? jsonDecode(r.data as String) : r.data;
    if (d is Map) return d['body'];
  } catch (_) {}
  throw 'El servidor todavía no tiene esta función (se está actualizando o falló la actualización). Espera unos minutos, toca Verificar en el inicio de sesión y revisa que diga versión s14.';
}

String _err(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['message'] != null) return d['message'].toString();
    return 'No hay conexión con el servidor';
  }
  return e.toString();
}

Map<String, dynamic> _mapa(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _lista(dynamic v) => v is List ? v.map((e) => _mapa(e)).toList() : <Map<String, dynamic>>[];
num _n(dynamic v) => v is num ? v : (num.tryParse('${v ?? ''}') ?? 0);

/// Cobranza del día: quién vence hoy, quién vence en pocos días y quién ya venció.
/// Cada persona de la sucursal avisa con un toque (WhatsApp o llamada) y queda anotado quién avisó.
class CobranzaPage extends StatefulWidget {
  const CobranzaPage({super.key});

  @override
  State<CobranzaPage> createState() => _CobranzaPageState();
}

class _CobranzaPageState extends State<CobranzaPage> {
  Map<String, dynamic> _d = {};
  bool _cargando = true;
  bool _todas = false;
  String _grupo = 'HOY';
  String? _error;

  UserEntity? get _user => context.read<Preferences>().token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/salud/cobranza', queryParameters: {
        'usuarioId': _user?.id ?? 0,
        'sucursalId': _user?.sucursal?.id ?? 0,
        if (_todas) 'todas': 1,
      });
      _d = _mapa(_cuerpo(r));
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _anotar(Map<String, dynamic> it, String canal) async {
    try {
      await _dio.post('/salud/cobranza/aviso', data: {
        'prestamoCodigo': it['codigo'],
        'usuarioId': _user?.id,
        'usuarioNombre': _user?.fullName,
        'canal': canal,
      });
      it['avisadoHoy'] = true;
      it['avisadoPor'] = _user?.fullName;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_err(e))));
    }
  }

  Future<void> _whatsapp(Map<String, dynamic> it) async {
    final cel = it['celular'];
    if (cel == null) return;
    final uri = Uri.parse('https://wa.me/$cel?text=${Uri.encodeComponent('${it['mensaje']}')}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) await _anotar(it, 'WHATSAPP');
  }

  Future<void> _llamar(Map<String, dynamic> it) async {
    final cel = '${it['celular'] ?? ''}';
    if (cel.isEmpty) return;
    final ok = await launchUrl(Uri.parse('tel:+$cel'));
    if (ok) await _anotar(it, 'LLAMADA');
  }

  @override
  Widget build(BuildContext context) {
    final res = _mapa(_d['resumen']);
    final todos = _lista(_d['items']);
    final items = todos.where((i) => i['grupo'] == _grupo).toList();
    final admin = _user?.isAdmin == true;
    Widget chip(String g, String t, num n, Color c) => ChoiceChip(
          label: Text('$t ($n)'),
          selected: _grupo == g,
          selectedColor: c.withOpacity(0.25),
          onSelected: (_) => setState(() => _grupo = g),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Cobranza de hoy')),
      body: Column(children: [
        if (admin)
          SwitchListTile(
            dense: true,
            title: const Text('Ver todas las sucursales', style: TextStyle(fontSize: 13)),
            value: _todas,
            onChanged: (v) {
              _todas = v;
              _cargar();
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Wrap(spacing: 8, children: [
            chip('HOY', 'Vencen hoy', _n(res['hoy']), Colors.orange),
            chip('PRONTO', 'Vencen pronto', _n(res['pronto']), Colors.blue),
            chip('VENCIDO', 'Ya vencieron', _n(res['vencidos']), Colors.red),
          ]),
        ),
        if (_d.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Avisados hoy: ${res['avisadosHoy']} · Sin celular: ${res['sinCelular']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ),
        if (_cargando) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargar,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
              if (!_cargando && items.isEmpty && _error == null) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nadie en esta lista. 👍'))),
              for (final it in items) _tarjeta(it),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tarjeta(Map<String, dynamic> it) {
    final dias = _n(it['dias']).toInt();
    final txtDias = dias > 0 ? 'Vence en $dias día${dias == 1 ? '' : 's'}' : (dias == 0 ? 'Vence HOY' : 'Vencido hace ${-dias} día${dias == -1 ? '' : 's'}');
    final color = dias < 0 ? Colors.red.shade700 : (dias == 0 ? Colors.orange.shade800 : Colors.blue.shade700);
    final tieneCel = it['celular'] != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${it['cliente']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5))),
            Text('S/ ${_n(it['saldo']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 2),
          Text('Préstamo ${it['codigoFormateado']} · ${it['sucursal'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text('$txtDias (${it['fechaVence']})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          if (it['enAdjudicacion'] == true) const Text('Ya está en proceso de adjudicación', style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
          if (it['avisadoHoy'] == true) Text('✔ Avisado hoy por ${it['avisadoPor'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.green.shade700))
          else if (it['ultimoAviso'] != null) Text('Último aviso: ${it['ultimoAviso']}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
          const SizedBox(height: 8),
          if (!tieneCel) const Text('Este cliente no tiene celular válido. Actualiza sus datos.', style: TextStyle(fontSize: 12, color: Colors.red))
          else
            Wrap(spacing: 8, runSpacing: 4, children: [
              FilledButton.icon(
                onPressed: () => _whatsapp(it),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                icon: const Icon(Icons.chat, size: 18),
                label: Text(it['avisadoHoy'] == true ? 'Avisar otra vez' : 'Avisar por WhatsApp'),
              ),
              OutlinedButton.icon(onPressed: () => _llamar(it), icon: const Icon(Icons.call, size: 18), label: const Text('Llamar')),
            ]),
        ]),
      ),
    );
  }
}
