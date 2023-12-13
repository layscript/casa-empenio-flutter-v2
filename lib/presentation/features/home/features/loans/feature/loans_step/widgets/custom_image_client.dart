import 'dart:io';
import 'package:flutter/material.dart';

class CustomImageClient extends StatelessWidget {
  const CustomImageClient({
    super.key,
    required this.onTap,
    required this.path,
  });
  final void Function()? onTap;
  final String path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Image.file(
            File(path),
            width: 100,
            height: 100,
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.red,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
