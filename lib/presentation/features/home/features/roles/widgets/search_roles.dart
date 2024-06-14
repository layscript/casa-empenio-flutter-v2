import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchRoles extends StatefulWidget {
  const SearchRoles({super.key});

  @override
  State<SearchRoles> createState() => _SearchRolesState();
}

class _SearchRolesState extends State<SearchRoles> {
  final nameCtrl = TextEditingController();
  bool nameIsValid = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextFormField(
            suffixIcon: GestureDetector(
              onTap: () {
                nameCtrl.clear();
                context.read<RolesBloc>().add(
                      const GetRoles(),
                    );
              },
              child: const Icon(
                Icons.clear,
              ),
            ),
            controller: nameCtrl,
            labelText: 'Buscar por nombre',
            isValid: (value) => setState(() => nameIsValid = value),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.read<RolesBloc>().add(
                    SearchRolesByName(value: nameCtrl.text),
                  );
            },
            child: const Text('Buscar'),
          ),
        ),
      ],
    );
  }
}
