import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/modulos/widgets/search_modulos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModulosViewLoaded extends StatefulWidget {
  const ModulosViewLoaded({
    super.key,
    required this.state,
  });
  final ModulosState state;

  @override
  State<ModulosViewLoaded> createState() => _ModulosViewLoadedState();
}

class _ModulosViewLoadedState extends State<ModulosViewLoaded> {
  final _scrollController = ScrollController();
  late int _offset;
  late List<ModulosEntity> _modulos;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _offset = 0;
    _modulos = widget.state.listModulos ?? [];
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
    final modulosRepository = context.read<ModulosRepository>();
    final result = await modulosRepository.getAllModulos(
      offset: search == null ? _offset : 0,
    );
    result.fold(
      (error) => null,
      (products) {
        if (search == null) {
          _modulos = _modulos + products;
        } else {
          _modulos = products;
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
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Lista de Módulos',
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
                        child: SearchModulos(),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                if (widget.state.listModulos.isNotEmpty) ...[
                  SliverList.builder(
                    itemCount: _loading ? _modulos.length + 1 : _modulos.length,
                    itemBuilder: (context, index) {
                      if (index < _modulos.length) {
                        final modulo = _modulos[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            'MÓDULO: ${modulo.nombre.toUpperCase()}',
                          ),
                          subtitle: Text(
                            'id: ${modulo.id}',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
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
                        'No hay módulos registrados',
                      ),
                    ),
                  )
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
