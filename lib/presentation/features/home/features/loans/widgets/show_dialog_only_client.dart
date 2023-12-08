/* import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShowDialogOnlyClient extends StatefulWidget {
  const ShowDialogOnlyClient({super.key, required this.document});
  final String document;

  @override
  State<ShowDialogOnlyClient> createState() => _ShowDialogOnlyClientState();
}

class _ShowDialogOnlyClientState extends State<ShowDialogOnlyClient> {
  @override
  void initState() {
    super.initState();
    callApi();
  }

  void callApi() {
    context.read<LoansBloc>().add(
          GetLoansSearchByDni(
            value: widget.document,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    /* return AlertDialog(
      title: Text(
        'Cliente: ${prestamo?.cliente?.nombres} ${prestamo?.cliente?.apellidos}',
      ),
    ); */
    return AlertDialog(
      scrollable: true,
      insetPadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 20,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      content: Builder(builder: (context) {
        var width = MediaQuery.of(context).size.width;

        return BlocBuilder<LoansBloc, LoansState>(
          builder: (context, state) {
            if (state.isLoansSearchClientLoading) {
              return SizedBox(
                width: width * 0.85,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 30),
                    CircularProgressIndicator(),
                    SizedBox(height: 30),
                  ],
                ),
              );
            }

            if (state.isLoansSearchClientError) {
              return SizedBox(
                width: width * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ocurrió un problema, inténtelo de nuevo',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        callApi();
                      },
                      child: const Text('Actualizar'),
                    ),
                  ],
                ),
              );
            }

            if (state.isLoansSearchClientSuccess) {
              final customer = state.searchCustomer;
              return SizedBox(
                width: width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Cliente: ${customer?.nombres} ${customer?.apellidos}'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 400,
                        child: ListViewLoansSuccess(
                          customer: customer,
                          hiddeOnTap: true,
                          typeSearch: state.typeSearch,
                          searchText: state.searchText,
                          state: state,
                        ),
                      )
                    ],
                  ),
                ),
              );
            }
            return SizedBox(
              width: width * 0.85,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 30),
                  CircularProgressIndicator(),
                  SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
 */