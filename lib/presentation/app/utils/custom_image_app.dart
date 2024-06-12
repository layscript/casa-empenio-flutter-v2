import 'package:cached_network_image/cached_network_image.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:flutter/material.dart';

class CustomImageApp extends StatelessWidget {
  const CustomImageApp({
    super.key,
    required this.urlImg,
    this.height = 50,
    this.width = 50,
  });
  final String urlImg;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(
              imageUrl: urlImg,
            ),
          ),
        );
      },
      child: CachedNetworkImage(
        imageUrl: '$endPointPrincipal/$urlImg',
        height: height,
        width: width,
        placeholder: (context, url) {
          return Placeholder(
            fallbackHeight: height,
            fallbackWidth: width,
          );
        },
        errorWidget: (context, url, error) {
          return Placeholder(
            fallbackHeight: height,
            fallbackWidth: width,
          );
        },
      ),
    );
  }
}
