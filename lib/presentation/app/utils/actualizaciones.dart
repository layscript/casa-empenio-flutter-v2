import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Número de la compilación instalada (lo pone el compilador automático; en pruebas locales es 0)
const int kBuildActual = int.fromEnvironment('BUILD_NUMBER', defaultValue: 0);

const _repo = 'layscript/casa-empenio-flutter-v2';
const _servidor = endPointPrincipal;
const _apkUrl = 'https://github.com/$_repo/releases/download/apk-latest/casa-empenio.apk';

class Actualizacion {
  Actualizacion({required this.numero, required this.titulo, required this.detalle, required this.fecha, this.tieneApk = false});
  final int numero;
  final String titulo;
  final String detalle;
  final DateTime? fecha;
  final bool tieneApk;
}

/// Última versión de la que ya se avisó (para no repetir el mismo aviso)
int _ultimoAvisado = 0;
List<Actualizacion> _cache = [];

/// Lee la lista de actualizaciones publicadas (la más nueva primero). Si no hay internet devuelve lo último que se pudo leer.
Future<List<Actualizacion>> buscarActualizaciones() async {
  try {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 10), headers: {'Accept': 'application/vnd.github+json'}));
    final r = await dio.get('https://api.github.com/repos/$_repo/releases', queryParameters: {'per_page': 40});
    final lista = <Actualizacion>[];
    for (final e in (r.data as List)) {
      final tag = (e['tag_name'] ?? '').toString();
      if (!tag.startsWith('build-')) continue;
      final n = int.tryParse(tag.substring(6));
      if (n == null) continue;
      final cuerpo = (e['body'] ?? '').toString().trim();
      final lineas = cuerpo.split('\n').where((l) => l.trim().isNotEmpty).toList();
      lista.add(Actualizacion(
        numero: n,
        titulo: lineas.isEmpty ? 'Mejoras y correcciones' : lineas.first.trim(),
        detalle: lineas.length > 1 ? lineas.skip(1).join('\n').trim() : '',
        fecha: DateTime.tryParse((e['published_at'] ?? '').toString())?.toLocal(),
        tieneApk: ((e['assets'] as List?) ?? []).any((x) => x['name'] == 'casa-empenio.apk'),
      ));
    }
    lista.sort((a, b) => b.numero.compareTo(a.numero));
    _cache = lista;
  } catch (_) {}
  return _cache;
}

Future<void> descargarApk() async {
  await launchUrl(Uri.parse(_apkUrl), mode: LaunchMode.externalApplication);
}

/// Descarga una versión anterior (por si una actualización falla)
Future<void> descargarVersion(int numero) async {
  await launchUrl(Uri.parse('https://github.com/$_repo/releases/download/build-$numero/casa-empenio.apk'), mode: LaunchMode.externalApplication);
}

/// Pregunta al servidor si está funcionando. Devuelve null si responde bien, o el motivo si no.
/// Versión que dice tener el servidor (se llena al verificar)
String versionServidor = '';

Future<String?> verificarServidor() async {
  try {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 6)));
    final r = await dio.get('$_servidor/health/live');
    if (r.statusCode == 200 && r.data is Map) {
      final d = r.data as Map;
      versionServidor = '${d['version'] ?? ''}${d['commit'] != null ? ' · ${d['commit']}' : ''}'.trim();
    }
    return r.statusCode == 200 ? null : 'El servidor respondió con un problema (${r.statusCode})';
  } on DioException catch (e) {
    if (e.response != null) return 'El servidor respondió con un problema (${e.response?.statusCode})';
    return 'No se puede conectar con el servidor. Revisa tu internet; si el internet está bien, el servidor está caído: avisa al administrador.';
  } catch (_) {
    return 'No se pudo verificar el servidor';
  }
}

/// Cuántas actualizaciones nuevas hay respecto a la instalada
int pendientes(List<Actualizacion> l) => kBuildActual <= 0 ? 0 : l.where((a) => a.numero > kBuildActual).length;

/// Avisa si hay una versión nueva. No bloquea el uso de la app.
/// [banner]: true = franja discreta arriba (mientras se trabaja); false = ventana (al abrir).
Future<void> avisarActualizacion(BuildContext context, {bool banner = false}) async {
  if (kBuildActual <= 0) return;
  final lista = await buscarActualizaciones();
  final nuevas = lista.where((a) => a.numero > kBuildActual).toList();
  if (nuevas.isEmpty || !context.mounted) return;
  final ultima = nuevas.first.numero;
  if (ultima <= _ultimoAvisado) return;
  _ultimoAvisado = ultima;
  final titulo = nuevas.length == 1 ? 'Hay 1 actualización nueva' : 'Hay ${nuevas.length} actualizaciones nuevas';

  if (banner) {
    final m = ScaffoldMessenger.of(context);
    m.clearMaterialBanners();
    m.showMaterialBanner(MaterialBanner(
      backgroundColor: Colors.blue.shade50,
      leading: const Icon(Icons.system_update, color: Colors.blue),
      content: Text('$titulo. Termina lo que estás haciendo y actualiza cuando puedas.', style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: m.hideCurrentMaterialBanner, child: const Text('Más tarde')),
        FilledButton(
          onPressed: () {
            m.hideCurrentMaterialBanner();
            descargarApk();
          },
          child: const Text('Actualizar'),
        ),
      ],
    ));
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(shrinkWrap: true, children: [
          const Text('Te recomendamos actualizar para tener las últimas mejoras. Puedes seguir trabajando y actualizar más tarde.', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 10),
          for (final a in nuevas.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${a.numero}. ${a.titulo}', style: const TextStyle(fontSize: 13)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Más tarde')),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            descargarApk();
          },
          icon: const Icon(Icons.download),
          label: const Text('Descargar'),
        ),
      ],
    ),
  );
}

/// Pantalla "Actualizaciones": historial numerado y botón para descargar la última
class ActualizacionesPage extends StatefulWidget {
  const ActualizacionesPage({super.key});
  @override
  State<ActualizacionesPage> createState() => _ActualizacionesPageState();
}

class _ActualizacionesPageState extends State<ActualizacionesPage> {
  List<Actualizacion> _lista = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    buscarActualizaciones().then((l) {
      if (mounted) setState(() { _lista = l; _cargando = false; });
    });
  }

  String _fecha(DateTime? d) => d == null ? '' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final nuevas = pendientes(_lista);
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizaciones')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(12), children: [
              Card(
                color: nuevas > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(kBuildActual <= 0 ? 'Versión de prueba' : 'Tienes instalada la actualización $kBuildActual', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(_lista.isEmpty ? 'No se pudo consultar. Revisa tu internet.' : (nuevas > 0 ? 'Hay $nuevas actualización(es) nueva(s) por instalar.' : 'Estás al día.')),
                    if (_lista.isNotEmpty && (nuevas > 0 || kBuildActual <= 0)) ...[
                      const SizedBox(height: 8),
                      FilledButton.icon(onPressed: descargarApk, icon: const Icon(Icons.download), label: const Text('Descargar la última versión')),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final a in _lista)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: a.numero == kBuildActual ? Colors.green : (a.numero > kBuildActual ? Colors.orange : Colors.blueGrey.shade200), child: Text('${a.numero}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                    title: Text(a.titulo, style: const TextStyle(fontSize: 14)),
                    subtitle: Text('${_fecha(a.fecha)}${a.numero == kBuildActual ? ' · instalada' : (a.numero > kBuildActual ? ' · nueva' : '')}${a.detalle.isEmpty ? '' : '\n${a.detalle}'}', style: const TextStyle(fontSize: 12)),
                    isThreeLine: a.detalle.isNotEmpty,
                    trailing: (a.tieneApk && a.numero != kBuildActual)
                        ? TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Instalar la actualización ${a.numero}'),
                                content: const Text('Úsalo solo si la última versión falla. Si Android no deja instalar una versión más antigua, desinstala la app primero (tus datos del servidor no se pierden) y vuelve a instalar.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                  FilledButton(onPressed: () { Navigator.pop(ctx); descargarVersion(a.numero); }, child: const Text('Descargar')),
                                ],
                              ),
                            ),
                            child: Text(a.numero > kBuildActual ? 'Instalar' : 'Volver'),
                          )
                        : null,
                  ),
                ),
            ]),
    );
  }
}
