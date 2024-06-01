import 'package:casa_empenio_pe/presentation/features/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DialogGlobalHome extends StatelessWidget {
  const DialogGlobalHome._({
    required this.homeBloc,
  });
  final HomeBloc homeBloc;

  static void show(BuildContext context, {required HomeBloc homeBloc}) {
    showDialog(
      context: context,
      builder: (context) => DialogGlobalHome._(
        homeBloc: homeBloc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Estás seguro de salir?'),
      content: const Text(
        'Si sales se perderán los cambios',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            homeBloc.add(GoToHome());
            Navigator.of(context).pop();
          },
          child: const Text('Salir'),
        ),
      ],
    );
  }
}
