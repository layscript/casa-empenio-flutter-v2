import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/buttons/buttons.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/roles/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RolesViewLoaded extends StatefulWidget {
  const RolesViewLoaded({
    super.key,
    required this.state,
  });
  final RolesState state;

  @override
  State<RolesViewLoaded> createState() => _RolesViewLoadedState();
}

class _RolesViewLoadedState extends State<RolesViewLoaded> {
  final _scrollController = ScrollController();
  late int _offset;
  late List<RoleEntity> _roles;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _offset = 0;
    _roles = widget.state.listRoles ?? [];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (_loading) return;
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _loading = true;
      });
      _offset = _offset + 10;
      await fetch(null);
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> fetch(String? search) async {
    final rolesRepository = context.read<RolRepository>();
    final result = await rolesRepository.getRoles(
      offset: search == null ? _offset : 0,
    );
    result.fold(
      (error) => null,
      (products) {
        if (search == null) {
          _roles = _roles + products;
        } else {
          _roles = products;
        }
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.only(
              bottom: 120,
            ),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Lista de Roles',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: SearchRoles(),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                if (widget.state.listRoles.isNotEmpty) ...[
                  SliverList.separated(
                    separatorBuilder: (context, index) => const Divider(
                      height: 20,
                    ),
                    itemCount: _loading ? _roles.length + 1 : _roles.length,
                    itemBuilder: (context, index) {
                      if (index < _roles.length) {
                        final rol = _roles[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            rol.nombre.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: rol.modulos!.isEmpty
                              ? const Text('No tiene modulos asignados')
                              : Text(
                                  'Contiene ${rol.modulos?.length} modulos asignados',
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) => ShowRolDialogInfo(
                                      rol: rol,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.remove_red_eye_sharp,
                                  color: AppColors.blue,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<RolesBloc>(),
                                        child: EditRolDialog(
                                          rol: rol,
                                          modules: widget.state.listModules,
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.yellow,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  ),
                ] else ...[
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No hay roles registrados',
                      ),
                    ),
                  )
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
              ],
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
                          value: context.read<RolesBloc>(),
                          child: const AddRolDialog(),
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
                      Text('Agregar Rol'),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
