import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:flutter/material.dart';

/// Visor de fotos a pantalla completa: se acerca con dos dedos (zoom), se mueve con un dedo,
/// doble toque para acercar o volver, y si hay varias fotos del mismo bien se pasan deslizando.
class FullScreenImage extends StatefulWidget {
  const FullScreenImage({super.key, required this.imageUrl, this.galeria = const [], this.titulo});

  /// Foto que se abre primero (ruta relativa al servidor).
  final String imageUrl;

  /// Todas las fotos del mismo grupo (por ejemplo las 3 del bien). Si está vacía, solo se ve [imageUrl].
  final List<String> galeria;
  final String? titulo;

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late final List<String> _fotos;
  late final PageController _pagina;
  int _actual = 0;
  bool _acercada = false;
  final Set<int> _dedos = {};

  @override
  void initState() {
    super.initState();
    _fotos = widget.galeria.where((e) => e.isNotEmpty).toList();
    if (!_fotos.contains(widget.imageUrl)) _fotos.insert(0, widget.imageUrl);
    _actual = _fotos.indexOf(widget.imageUrl);
    _pagina = PageController(initialPage: _actual);
  }

  @override
  void dispose() {
    _pagina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _fotos.length > 1 ? '${widget.titulo ?? 'Foto'}  ${_actual + 1}/${_fotos.length}' : (widget.titulo ?? 'Foto'),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Stack(children: [
        // Con 2 dedos en la pantalla (pellizco) la lista de fotos no se mueve: el zoom empieza al instante.
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => setState(() => _dedos.add(e.pointer)),
          onPointerUp: (e) => setState(() => _dedos.remove(e.pointer)),
          onPointerCancel: (e) => setState(() => _dedos.remove(e.pointer)),
          child: PageView.builder(
          controller: _pagina,
          // con la foto acercada o con 2 dedos, deslizar mueve/acerca la foto; solo con 1 dedo y sin acercar, cambia de foto
          physics: (_acercada || _dedos.length >= 2) ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
          itemCount: _fotos.length,
          onPageChanged: (i) => setState(() {
            _actual = i;
            _acercada = false;
          }),
          itemBuilder: (_, i) => ZoomableImage(
            key: ValueKey(_fotos[i]),
            proveedor: CachedNetworkImageProvider('$endPointPrincipal/${_fotos[i]}'),
            alCambiarZoom: (z) {
              if (z != _acercada && i == _actual) setState(() => _acercada = z);
            },
          ),
        )),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: SafeArea(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'Acerca con dos dedos · doble toque para ampliar',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Imagen con zoom (pellizco), movimiento y doble toque. Sirve para cualquier [ImageProvider].
class ZoomableImage extends StatefulWidget {
  const ZoomableImage({super.key, required this.proveedor, this.alCambiarZoom});
  final ImageProvider proveedor;
  final void Function(bool acercada)? alCambiarZoom;

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  final TransformationController _ctl = TransformationController();
  Offset _toque = Offset.zero;
  bool _acercada = false;
  int _ultimoToque = 0;
  Offset _ultimaPos = Offset.zero;
  final Set<int> _punteros = {};
  bool _huboMovimiento = false;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() {
      final z = _ctl.value.getMaxScaleOnAxis() > 1.02;
      if (z != _acercada) {
        _acercada = z;
        widget.alCambiarZoom?.call(z);
      }
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _dobleToque() {
    if (_ctl.value.getMaxScaleOnAxis() > 1.02) {
      _ctl.value = Matrix4.identity();
    } else {
      const s = 3.0;
      final tx = -_toque.dx * (s - 1);
      final ty = -_toque.dy * (s - 1);
      _ctl.value = Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
    }
  }

  // El doble toque se detecta a mano (sin GestureDetector) para que no compita con el pellizco:
  // así el zoom con dos dedos empieza de inmediato.
  void _alBajar(PointerDownEvent e) {
    _punteros.add(e.pointer);
    if (_punteros.length > 1) {
      _ultimoToque = 0;
      return;
    }
    _huboMovimiento = false;
    _toque = e.localPosition;
  }

  void _alMover(PointerMoveEvent e) {
    if ((e.delta.distance) > 0.5 && (e.localPosition - _toque).distance > 12) _huboMovimiento = true;
  }

  void _alSubir(PointerUpEvent e) {
    final eraUnico = _punteros.length == 1;
    _punteros.remove(e.pointer);
    if (!eraUnico || _huboMovimiento) {
      _ultimoToque = 0;
      return;
    }
    final ahora = DateTime.now().millisecondsSinceEpoch;
    if (ahora - _ultimoToque < 300 && (e.localPosition - _ultimaPos).distance < 60) {
      _ultimoToque = 0;
      _toque = e.localPosition;
      _dobleToque();
    } else {
      _ultimoToque = ahora;
      _ultimaPos = e.localPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _alBajar,
      onPointerMove: _alMover,
      onPointerUp: _alSubir,
      onPointerCancel: (e) {
        _punteros.remove(e.pointer);
        _ultimoToque = 0;
      },
      child: InteractiveViewer(
        transformationController: _ctl,
        minScale: 1,
        maxScale: 8,
        child: SizedBox.expand(
          child: Image(
            image: widget.proveedor,
            fit: BoxFit.contain,
            loadingBuilder: (_, hijo, progreso) => progreso == null
                ? hijo
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorBuilder: (_, __, ___) => const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                SizedBox(height: 8),
                Text('No se pudo cargar la foto', style: TextStyle(color: Colors.white70)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenImageUint8List extends StatelessWidget {
  const FullScreenImageUint8List({super.key, required this.image});
  final Uint8List image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
      body: ZoomableImage(proveedor: MemoryImage(image)),
    );
  }
}
