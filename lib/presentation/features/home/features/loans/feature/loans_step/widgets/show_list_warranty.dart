import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShowListWarranty extends StatelessWidget {
  const ShowListWarranty({
    super.key,
    required this.listWarranty,
  });
  final List<WarrantyState>? listWarranty;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state as Authenticated;
    final preferences = context.read<Preferences>();
    final localState =
        preferences.getLoansPreferences ?? LoansPreferencesEntity.init();

    return Column(
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          shrinkWrap: true,
          itemCount: listWarranty!.length,
          itemBuilder: (context, index) {
            final warranty = listWarranty![index];

            return ExpansionTile(
              title: Text('Garantía: ${index + 1}'),
              collapsedTextColor: AppColors.primaryText,
              textColor: AppColors.primaryText,
              collapsedIconColor: AppColors.blue,
              iconColor: AppColors.blue,
              backgroundColor: const Color.fromARGB(255, 228, 228, 244),
              collapsedBackgroundColor:
                  const Color.fromARGB(255, 228, 228, 244),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text('Descripción: ${warranty.description}'),
                Text('Categoria: ${warranty.category?.descripcion}'),
                if ((warranty.model ?? '').isNotEmpty)
                  Text('Modelo: ${warranty.model}'),
                if ((warranty.brand ?? '').isNotEmpty)
                  Text('Marca: ${warranty.brand}'),
                if (warranty.placa != null) Text('Placa: ${warranty.placa}'),
                if ((warranty.color ?? '').isNotEmpty)
                  Text('Color: ${warranty.color}'),
                if ((warranty.status ?? '').isNotEmpty)
                  Text('Estado: ${warranty.status}'),
                if ((warranty.serie ?? '').isNotEmpty)
                  Text('Serie: ${warranty.serie}'),
                Text('Observaciones: ${warranty.warrantyObservations}'),
                Text('Precio Referencial: ${warranty.price}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 0;
                        i < (warranty.photoWarranty?.length ?? 0);
                        i++)
                      Image.file(
                        File(warranty.photoWarranty![i].path),
                        width: 100,
                        height: 100,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.yellow,
                        ),
                        onPressed: () => context
                            .read<LoansStepBloc>()
                            .add(ChangeStatusEditListWarranty(
                              value: true,
                              id: warranty.id!,
                            )),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppColors.red,
                        ),
                        onPressed: () => context.read<LoansStepBloc>().add(
                              DeleteListWarranty(
                                localState: localState,
                                value: warranty,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          alignment: Alignment.centerRight,
          child: FloatingActionButton(
            backgroundColor: AppColors.darkBlue,
            onPressed: () => context.read<LoansStepBloc>().add(
                  const ChangeStatusAddListWarranty(
                    value: true,
                  ),
                ),
            child: const Icon(
              Icons.add,
            ),
          ),
        ),
        const SizedBox(height: 50),
        SecondaryButton(
          onPressed: () => context.read<LoansStepBloc>().add(
                const ChangeIndexLoans(
                  index: 1,
                ),
              ),
          child: const Text('Volver'),
        ),
        const SizedBox(height: 15),
        PrimaryButton(
          onPressed: listWarranty != null
              ? () => context.read<LoansStepBloc>().add(
                    SaveAllLoan(auth.user?.id.toString() ?? '1'),
                  )
              : null,
          child: const Text('Registrar Préstamo'),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
