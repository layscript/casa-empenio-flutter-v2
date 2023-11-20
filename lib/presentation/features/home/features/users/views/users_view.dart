import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/users/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => UsersBloc(
        userRepository: context.read(),
      )..add(GetUsers()),
      child: Builder(builder: (context) {
        return BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            switch (state) {
              case UsersLoading() || UsersInitial():
                return const Center(
                  child: CupertinoActivityIndicator(),
                );

              case UsersError():
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<UsersBloc>().add(GetUsers()),
                        child: const Text(
                          'Cargar de nuevo',
                        ),
                      )
                    ],
                  ),
                );
              case UsersLoaded():
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: MediaQuery.of(context).size.height * 0.9,
                        padding: const EdgeInsets.only(
                          bottom: 120,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Lista de Usuarios',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(
                                  height: 10,
                                ),
                                shrinkWrap: true,
                                itemCount: state.listUsers.length,
                                itemBuilder: (context, index) {
                                  final user = state.listUsers[index];
                                  return ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${user.nombre} ${user.apellido}',
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                user.userName,
                                                maxLines: 3,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: AppColors.yellow,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (_) {
                                                    return BlocProvider.value(
                                                      value: context
                                                          .read<UsersBloc>(),
                                                      child: EditUserDialog(
                                                        user: user,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: AppColors.red,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (_) {
                                                    return DeleteDialog(
                                                      title: 'Usuario',
                                                      onPressed: () => context
                                                          .read<UsersBloc>()
                                                          .add(
                                                            DeleteUser(
                                                              id: user.id,
                                                            ),
                                                          ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: null,
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: defaultBoxShadow,
                          ),
                          child: Center(
                            child: PrimaryButton(
                              onPressed: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (_) {
                                    return BlocProvider.value(
                                      value: context.read<UsersBloc>(),
                                      child: const AddUserDialog(),
                                    );
                                  },
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.circlePlus),
                                  SizedBox(width: 10),
                                  Text('Agregar Usuario'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );

              default:
            }

            return const SizedBox();
          },
        );
      }),
    );
  }
}
