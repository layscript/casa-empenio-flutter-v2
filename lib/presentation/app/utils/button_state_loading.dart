import 'package:flutter/material.dart';

class ButtonStateLoading extends StatelessWidget {
  const ButtonStateLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
