import 'dart:typed_data';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return FadeInImage.assetNetwork(
        fit: BoxFit.fitWidth,
        placeholder: 'assets/image/loading.gif',
        image: '$endPoint/$imageUrl');
  }
}

class FullScreenImageUint8List extends StatelessWidget {
  final Uint8List image;
  const FullScreenImageUint8List({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Image.memory(image);
  }
}
