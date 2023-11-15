import 'dart:developer';

import 'package:casa_empenio_pe/presentation/app/utils/keyboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OverlayLoader extends StatelessWidget {
  const OverlayLoader._();
  static OverlayEntry? _currentOverlayLoader;
  static OverlayState? _overlayState;

  static bool get isShowing => _currentOverlayLoader?.mounted == true;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Padding(
        padding: const EdgeInsets.all(24).copyWith(
          bottom: 24,
        ),
        child: const Center(
          child: CupertinoActivityIndicator(
            color: Colors.white,
            radius: 14,
          ),
        ),
      ),
    );
  }

  static void show(BuildContext context) {
    _overlayState = Overlay.of(context);
    if (_currentOverlayLoader == null) {
      _currentOverlayLoader = OverlayEntry(
        builder: (context) {
          return Stack(
            children: <Widget>[
              Container(
                color: Colors.black26,
              ),
              const Center(
                child: OverlayLoader._(),
              ),
            ],
          );
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Keyboard.unfocus(context);
        if (_currentOverlayLoader != null) {
          try {
            if (!isShowing) {
              _overlayState?.insert(_currentOverlayLoader!);
            }
          } catch (e) {
            log('overlay loader: $e');
          }
        }
      });
    }
  }

  static void hide() {
    if (_currentOverlayLoader != null) {
      try {
        if (isShowing) {
          _currentOverlayLoader!.remove();
        }
      } catch (e) {
        log('overlay loader $e');
      }
      _currentOverlayLoader = null;
    }
  }
}
