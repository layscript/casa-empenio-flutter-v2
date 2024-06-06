import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/features.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShowDialogClients extends StatelessWidget {
  const ShowDialogClients({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => ClientBloc(
        customerRepository: context.read(),
      )..add(GetClients()),
      child: Builder(builder: (context) {
        return AlertDialog(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          scrollable: true,
          title: const Text(
            'Seleccionar Clientes',
          ),
          content: BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              switch (state) {
                case ClientLoading() || ClientInitial():
                  return const Center(
                    child: CupertinoActivityIndicator(),
                  );

                case ClientError():
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
                              context.read<ClientBloc>().add(GetClients()),
                          child: const Text(
                            'Cargar de nuevo',
                          ),
                        )
                      ],
                    ),
                  );

                case ClientLoaded():
                  return SizedBox(
                    height: 500.0,
                    width: 300.0,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          AppTextFormField(
                            labelText: 'Buscar',
                            onChanged: (e) => context
                                .read<ClientBloc>()
                                .add(SearchClientByText(e)),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: state.customer.length,
                            itemBuilder: (BuildContext context, int index) {
                              final client = state.customer[index];
                              return ListTile(
                                title: Text(state.fullNames(client)),
                                subtitle: Text('${client.dni}'),
                                trailing: TextButton(
                                  style: const ButtonStyle(
                                      padding: MaterialStatePropertyAll(
                                    EdgeInsets.zero,
                                  )),
                                  onPressed: () {
                                    Navigator.pop(context, client);
                                  },
                                  child: const Text('Seleccionar'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
              }
            },
          ),
          actions: [
            TextButton(
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(AppColors.red),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Salir',
                style: TextStyle(color: AppColors.white),
              ),
            )
          ],
        );
      }),
    );
  }
}
