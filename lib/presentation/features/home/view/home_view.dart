import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);
  static const route = 'home';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Casa de Empeño'),
            centerTitle: true,
          ),
          drawer: const AppDrawer(),
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              switch (state.index) {
                case 0:
                  return Center(
                    child: Text('Inicio:'),
                  );

                case 1:
                  return const LoansView();
              }
              return SizedBox();
            },
          ),
        );
      }),
    );
  }
}
