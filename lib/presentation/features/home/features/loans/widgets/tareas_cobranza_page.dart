import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cartel de la pantalla de inicio: cuántas tareas de cobranza hay hoy.
class AvisoCobranza extends StatefulWidget {
  const AvisoCobranza({super.key});

  @override
  State<AvisoCobranza> createState() => _AvisoCobranzaState();
}

class _AvisoCobranzaState extends State<AvisoCobranza> {
  int _n = 0;
  Timer? _timer;
  bool _dialogoAbierto = false;

  /// Desde cuándo hay tareas sin resolver (para endurecer el aviso pasada 1 hora).
  static DateTime? _pendienteDesde;

  @override
  void initState() {
    super.initState();
    _cargar(recordar: true);
    _timer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _cargar(recordar: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool recordar = false}) async {
    try {
      final sid = context.read<Preferences>().token?.sucursal?.id ?? 1;
      final t = await context.read<SalesRepository>().tareasCobranza(sid);
      final n = t
          .where((e) => e['tarea'] != null && e['tarea'] != 'ADJUDICAR_AHORA')
          .length;
      if (n == 0) _pendienteDesde = null;
      if (n > 0) _pendienteDesde ??= DateTime.now();
      if (!mounted) return;
      setState(() => _n = n);
      if (recordar && n > 0 && !_dialogoAbierto) await _recordar(n);
    } catch (_) {}
  }

  Future<void> _abrir() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const TareasCobranzaPage()),
    );
    if (mounted) _cargar();
  }

  Future<void> _recordar(int n) async {
    final fuerte = DateTime.now().difference(_pendienteDesde!).inMinutes >= 60;
    _dialogoAbierto = true;
    final ir = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: !fuerte,
      builder: (c) => PopScope(
        canPop: !fuerte,
        child: AlertDialog(
          icon: Icon(Icons.notifications_active,
              color: fuerte ? Colors.red : Colors.orange, size: 40),
          title: Text(fuerte
              ? 'URGENTE: avisos sin hacer'
              : 'Tienes avisos por hacer hoy'),
          content: Text(
            'Hay $n cliente(s) con préstamo vencido que debes avisar o '
            'consultar HOY. Es obligatorio: sin esto no podrás cerrar la caja '
            'y el bien no se puede adjudicar.',
          ),
          actions: [
            if (!fuerte)
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Recordármelo en 10 min'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Resolver ahora'),
            ),
          ],
        ),
      ),
    );
    _dialogoAbierto = false;
    if (ir == true && mounted) await _abrir();
  }

  @override
  Widget build(BuildContext context) {
    if (_n == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: ListTile(
        leading: Icon(Icons.notifications_active, color: Colors.orange.shade800),
        title: Text('Tienes $_n tarea(s) de cobranza',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Obligatorio hoy: sin resolver no se cierra la caja'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _abrir,
      ),
    );
  }
}

class TareasCobranzaPage extends StatefulWidget {
  const TareasCobranzaPage({super.key});

  @override
  State<TareasCobranzaPage> createState() => _TareasCobranzaPageState();
}

class _TareasCobranzaPageState extends State<TareasCobranzaPage> {
  List<Map<String, dynamic>> _tareas = [];
  bool _cargando = true;
  final _hist = <int, List<Map<String, dynamic>>>{};

  SalesRepository get _repo => context.read<SalesRepository>();
  int get _uid =>
      (context.read<AuthBloc>().state as Authenticated).user?.id ?? 1;
  String get _unombre =>
      (context.read<AuthBloc>().state as Authenticated).user?.fullName ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
    _repo.canalesCobranza().then((c) {
      if (mounted) setState(() => _canales = c);
    });
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final sid = context.read<Preferences>().token?.sucursal?.id ?? 1;
    final t = await _repo.tareasCobranza(sid);
    if (!mounted) return;
    setState(() {
      _tareas = t;
      _cargando = false;
    });
  }

  void _msg(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? Colors.red : null,
    ));
  }

  Future<void> _accion(
    Map<String, dynamic> t,
    String accion,
    Map<String, dynamic> body, {
    String ok = 'Registrado',
  }) async {
    final err = await _repo.accionCobranza(
      t['prestamoCodigo'] as int,
      accion,
      {...body, 'usuarioId': _uid, 'usuarioNombre': _unombre},
    );
    if (!mounted) return;
    if (err != null) {
      _msg(err, error: true);
    } else {
      _msg(ok);
      _hist.remove(t['prestamoCodigo']);
      await _cargar();
    }
  }

  Future<bool> _confirmar(String titulo, String texto) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sí')),
        ],
      ),
    );
    return r ?? false;
  }

  String _cel(Map<String, dynamic> t) {
    final c = ((t['cliente'] as Map?)?['celular'] ?? '')
        .toString()
        .replaceAll(RegExp(r'\D'), '');
    return c;
  }

  int _nroAviso(Map<String, dynamic> t) => t['estado'] == 'AVISO_2' ? 2 : 1;

  Future<void> _sms(Map<String, dynamic> t) async {
    final c = _cel(t);
    if (c.length != 9) {
      _msg('El cliente no tiene un celular válido', error: true);
      return;
    }
    final auto = _canales['sms'] == true;
    final modo = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('¿Cómo enviar el mensaje de texto?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy, color: Colors.indigo),
            title: const Text('Automático (lo envía el sistema)'),
            subtitle: Text(auto
                ? 'Queda la constancia del proveedor en el sistema.'
                : 'No está configurado todavía.'),
            enabled: auto,
            onTap: auto ? () => Navigator.pop(ctx, 'auto') : null,
          ),
          ListTile(
            leading: const Icon(Icons.sms, color: Colors.indigo),
            title: const Text('Normal (desde mi celular)'),
            subtitle: const Text('Se abre tu app de mensajes con el texto listo.'),
            onTap: () => Navigator.pop(ctx, 'normal'),
          ),
        ]),
      ),
    );
    if (modo == null || !mounted) return;
    if (modo == 'auto') {
      final err = await _repo.accionCobranza(
        t['prestamoCodigo'] as int,
        'sms',
        {'usuarioId': _uid, 'usuarioNombre': _unombre},
      );
      if (!mounted) return;
      if (err == null) {
        _msg('SMS enviado y registrado');
        _hist.remove(t['prestamoCodigo']);
        await _cargar();
        return;
      }
      final manual = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No se pudo enviar el SMS automático'),
          content: SingleChildScrollView(child: Text(err)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cerrar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enviarlo desde mi celular')),
          ],
        ),
      );
      if (manual != true || !mounted) return;
    }
    final texto =
        (_nroAviso(t) == 1 ? t['mensajeAviso1'] : t['mensajeAviso2']).toString();
    await launchUrl(
      Uri.parse('sms:$c?body=${Uri.encodeComponent(texto)}'),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (await _confirmar('Mensaje de texto', '¿Ya enviaste el mensaje de texto?')) {
      await _accion(t, 'contacto', {
        'canal': 'SMS',
        'resultado': 'ENVIADO',
        'telefono': '51$c',
        'mensaje': texto,
      });
    }
  }

  Map<String, dynamic> _canales = {'sms': false, 'whatsapp': false};

  Future<void> _whatsapp(Map<String, dynamic> t) async {
    final c0 = _cel(t);
    if (c0.isEmpty) {
      _msg('El cliente no tiene celular', error: true);
      return;
    }
    final auto = _canales['whatsapp'] == true;
    final modo = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('¿Cómo enviar el WhatsApp?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy, color: Colors.green),
            title: const Text('Automático (lo envía el sistema)'),
            subtitle: Text(auto
                ? 'Queda la constancia de envío en el sistema.'
                : 'Aún no está activado: requiere contratar la API oficial de WhatsApp.'),
            enabled: auto,
            onTap: auto ? () => Navigator.pop(ctx, 'auto') : null,
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text('Normal (se abre tu WhatsApp)'),
            subtitle: const Text('Tú lo envías y confirmas aquí.'),
            onTap: () => Navigator.pop(ctx, 'normal'),
          ),
        ]),
      ),
    );
    if (modo == null || !mounted) return;
    if (modo == 'auto') {
      await _accion(t, 'whatsapp', {}, ok: 'WhatsApp enviado y registrado');
      return;
    }
    final c = _cel(t);
    if (c.isEmpty) {
      _msg('El cliente no tiene celular', error: true);
      return;
    }
    final numero = c.length == 9 ? '51$c' : c;
    final texto =
        (_nroAviso(t) == 1 ? t['mensajeAviso1'] : t['mensajeAviso2']).toString();
    await launchUrl(
      Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(texto)}'),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (await _confirmar('WhatsApp', '¿Ya enviaste el mensaje por WhatsApp?')) {
      await _accion(t, 'contacto', {
        'canal': 'WHATSAPP',
        'resultado': 'ENVIADO',
        'telefono': numero,
        'mensaje': texto,
      });
    }
  }

  Future<void> _llamar(Map<String, dynamic> t) async {
    final c = _cel(t);
    if (c.isEmpty) {
      _msg('El cliente no tiene celular', error: true);
      return;
    }
    await launchUrl(Uri.parse('tel:$c'));
    if (!mounted) return;
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('¿Cómo salió la llamada?'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'RESPONDIO'),
              child: const Text('Contestó y se comunicó')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'SIN_RESPUESTA'),
              child: const Text('No contestó')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'NUMERO_ERRONEO'),
              child: const Text('Número errado / apagado')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar')),
        ],
      ),
    );
    if (r == null) return;
    await _accion(t, 'contacto', {
      'canal': 'LLAMADA',
      'resultado': r,
      'telefono': c,
    });
  }

  Future<void> _sinWhatsapp(Map<String, dynamic> t) async {
    if (!await _confirmar('Sin WhatsApp',
        '¿El cliente no tiene WhatsApp? Quedará anotado y solo falta SMS y llamada.')) {
      return;
    }
    await _accion(t, 'contacto', {
      'canal': 'WHATSAPP',
      'resultado': 'NUMERO_ERRONEO',
      'nota': 'El cliente no tiene WhatsApp',
    });
  }

  Widget _fila(String canal, String nombre, IconData icono, Color color,
      List hechos, VoidCallback onTap, String boton,
      {VoidCallback? alterno, String? textoAlterno}) {
    final ok = hechos.contains(canal);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.white,
        border: Border.all(color: ok ? Colors.green : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : icono, color: ok ? Colors.green : color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(nombre,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        if (!ok && alterno != null)
          TextButton(
              onPressed: alterno, child: Text(textoAlterno ?? '',
                  style: const TextStyle(fontSize: 12))),
        if (ok)
          const Text('Listo', style: TextStyle(color: Colors.green))
        else
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: color,
                visualDensity: VisualDensity.compact),
            onPressed: onTap,
            child: Text(boton),
          ),
      ]),
    );
  }

  Widget _checklist(Map<String, dynamic> t) {
    final hechos = (t['canalesHechos'] as List?) ?? [];
    final n = hechos.length;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aviso ${t['nroAviso']}: usa los 3 medios ($n de 3)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _fila('WHATSAPP', 'WhatsApp', Icons.chat, Colors.green.shade700,
              hechos, () => _whatsapp(t), 'Enviar',
              alterno: () => _sinWhatsapp(t), textoAlterno: 'No tiene'),
          _fila('SMS', 'Mensaje de texto (SMS)', Icons.sms,
              Colors.indigo, hechos, () => _sms(t), 'Enviar'),
          _fila('LLAMADA', 'Llamada', Icons.call, Colors.blue, hechos,
              () => _llamar(t), 'Llamar'),
          TextButton(
              onPressed: () => _otroMedio(t),
              child: const Text('Agregar una nota (otro medio)')),
        ],
      ),
    );
  }

  Future<void> _otroMedio(Map<String, dynamic> t) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Aviso por otro medio'),
        content: TextField(
          controller: ctrl,
          maxLength: 250,
          decoration: const InputDecoration(
              hintText: 'Ej: Se le avisó a su familiar en persona'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Registrar')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    await _accion(t, 'contacto', {
      'canal': 'OTRO',
      'resultado': 'NOTA',
      'nota': ctrl.text.trim(),
    });
  }

  Future<void> _verHistorial(Map<String, dynamic> t) async {
    final cod = t['prestamoCodigo'] as int;
    if (_hist.containsKey(cod)) {
      setState(() => _hist.remove(cod));
      return;
    }
    final d = await _repo.detalleCobranza(cod);
    final l = (d['contactos'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (mounted) setState(() => _hist[cod] = l);
  }

  String _fecha(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    if (d == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm')
        .format(d.toUtc().subtract(const Duration(hours: 5)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobranza y adjudicación'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _tareas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay préstamos en proceso de adjudicación.\n'
                      'Cuando un préstamo cumpla 60 días vencido aparecerá aquí.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tareas.length,
                  itemBuilder: (_, i) => _tarjeta(_tareas[i]),
                ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> t) {
    final cli = (t['cliente'] as Map?) ?? {};
    final nombre = '${cli['nombres'] ?? ''} ${cli['apellidos'] ?? ''}'.trim();
    final tarea = t['tarea']?.toString();
    final hist = _hist[t['prestamoCodigo']];
    final cod = t['codigoFormateado'] ?? t['prestamoCodigo'];

    final botones = <Widget>[];
    if (tarea == 'ENVIAR_AVISO_1' || tarea == 'ENVIAR_AVISO_2') {
      botones.add(_checklist(t));
    } else if (tarea == 'CONSULTAR_RESPUESTA') {
      botones.addAll([
        FilledButton.icon(
            onPressed: () async {
              if (await _confirmar('El cliente respondió',
                  'Se le dará un plazo extra y, si no recoge su bien, se adjudicará solo. ¿Confirmas?')) {
                await _accion(t, 'respuesta', {'respondio': true});
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Sí, se comunicó')),
        OutlinedButton.icon(
            onPressed: () async {
              if (await _confirmar('El cliente NO respondió',
                  'El bien se adjudicará hoy a las 00:00 (o ahora si lo decides). ¿Confirmas?')) {
                await _accion(t, 'respuesta', {'respondio': false});
              }
            },
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('No respondió')),
      ]);
    } else if (tarea == 'ADJUDICAR_AHORA') {
      botones.add(FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () async {
            if (await _confirmar('Adjudicar ahora',
                'El bien pasará a la venta ahora mismo. ¿Confirmas?')) {
              await _accion(t, 'adjudicar', {}, ok: 'Bien adjudicado');
            }
          },
          icon: const Icon(Icons.gavel),
          label: const Text('Adjudicar ahora')));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('N° $cod · $nombre',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Chip(
                label: Text('${t['diasVencido']} días',
                    style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              ),
            ]),
            Text('Celular: ${cli['celular'] ?? '-'}  ·  Saldo S/.${(t['saldo'] as num).toStringAsFixed(2)}\n'
                'Se adjudica como máximo en ${t['diasParaLimite']} día(s)'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tarea != null
                    ? Colors.orange.shade50
                    : Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t['detalle']?.toString() ?? ''),
            ),
            if (botones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: botones),
            ],
            TextButton.icon(
              onPressed: () => _verHistorial(t),
              icon: Icon(hist == null ? Icons.history : Icons.expand_less),
              label: Text(hist == null ? 'Ver avisos registrados' : 'Ocultar'),
            ),
            if (hist != null)
              if (hist.isEmpty)
                const Text('Aún no hay avisos registrados.')
              else
                for (final h in hist)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${_fecha(h['fecha'])} · ${h['canal']} · ${h['resultado']}'
                      '${h['nroAviso'] != null ? ' (aviso ${h['nroAviso']})' : ''}'
                      '${h['automatico'] == true ? ' · automático' : ''}'
                      '${(h['nota'] ?? '').toString().isNotEmpty ? ' · ${h['nota']}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
