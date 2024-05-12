import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/users/bloc/users_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.user,
  });
  final UserEntity user;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final fullNamesCtrl = TextEditingController();
  final fullLastNamesCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  SucursalEntity? sucursal;

  bool fullNamesIsValid = false;
  bool fullLastNamesIsValid = false;
  bool emailIsValid = false;
  bool userIsValid = false;
  bool passwordIsValid = false;
  bool confirmIsValid = false;
  bool sucursalIsValid = false;

  @override
  void initState() {
    super.initState();
    fullNamesCtrl.text = widget.user.nombre;
    fullLastNamesCtrl.text = widget.user.apellido;
    emailCtrl.text = widget.user.email;
    usernameCtrl.text = widget.user.userName;
    sucursal = widget.user.sucursal;

    fullNamesIsValid = true;
    fullLastNamesIsValid = true;
    emailIsValid = true;
    userIsValid = true;
    passwordIsValid = true;
    confirmIsValid = true;
    sucursalIsValid = true;
  }

  @override
  Widget build(BuildContext context) {
    final usersBloc = context.read<UsersBloc>();

    return AlertDialog(
      scrollable: true,
      title: const Text('Editar Usuario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            controller: fullNamesCtrl,
            labelText: 'Nombres',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => fullNamesIsValid = value),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            controller: fullLastNamesCtrl,
            labelText: 'Apellidos',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => fullLastNamesIsValid = value),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            controller: emailCtrl,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value!.isEmpty) return 'Campo Requerido';
              if (!validatorEmail(value)) return 'Correo inválido';
              return null;
            },
            isValid: (value) => setState(() => emailIsValid = value),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            controller: usernameCtrl,
            labelText: 'Username',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => userIsValid = value),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            obscureText: true,
            controller: passwordCtrl,
            labelText: 'Contraseña',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => passwordIsValid = value),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            obscureText: true,
            controller: confirmPasswordCtrl,
            labelText: 'Confirmar Contraseña',
            validator: (value) {
              if (value!.isEmpty) return invalidEmptyValue;
              if (value != passwordCtrl.text) {
                return 'Las contraseñas no son iguales';
              }
              return null;
            },
            isValid: (value) => setState(() => confirmIsValid = value),
          ),
          const SizedBox(height: 20),
          AppDropdownButtonFormField<SucursalEntity?>(
            value: sucursal,
            items: usersBloc.state.listSucursales
                ?.map(
                  (e) => DropdownMenuItem<SucursalEntity?>(
                    value: e,
                    child: Text(e.nombre),
                  ),
                )
                .toList(),
            onChanged: (e) {
              setState(() {
                sucursal = e;
                sucursalIsValid = true;
              });
            },
            labelText: 'Sucursal',
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: !fullNamesIsValid ||
                  !fullLastNamesIsValid ||
                  !emailIsValid ||
                  !userIsValid ||
                  !passwordIsValid ||
                  !confirmIsValid ||
                  !sucursalIsValid
              ? null
              : () {
                  Navigator.pop(context);
                  context.read<UsersBloc>().add(
                        UpdateUser(
                          rolId: widget.user.role?.id ?? 0,
                          id: widget.user.id,
                          celular: widget.user.celular ?? 0,
                          fullNames: fullNamesCtrl.text,
                          fullLastNames: fullLastNamesCtrl.text,
                          email: emailCtrl.text,
                          username: usernameCtrl.text,
                          password: passwordCtrl.text,
                          confirmPassword: confirmPasswordCtrl.text,
                          sucursalId: sucursal?.id ?? 1,
                        ),
                      );
                },
          icon: const Icon(Icons.save),
          label: const Text('Actualizar'),
        ),
        const SizedBox(height: 15),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: AppColors.red,
          ),
          label: const Text(
            'Salir',
            style: TextStyle(
              color: AppColors.red,
            ),
          ),
        ),
      ],
    );
  }
}
