import 'package:flutter/material.dart';

class TermsPrivacy extends StatelessWidget {
  const TermsPrivacy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        text: 'Al usar esta Aplicación, usted acepta nuestros',
        style: TextStyle(
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: ' Términos de Servicio ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: 'y nuestra'),
          TextSpan(
            text: ' Política de Privacidad. ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
