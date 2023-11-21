import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepThreeView extends StatelessWidget {
  const LoansStepThreeView({super.key});

  @override
  Widget build(BuildContext context) {
    final loansState = context.watch<LoansStepBloc>().state;
    if (loansState.listWarranty != null && !loansState.addListWarranty) {
      return _ListWarranty(loansState: loansState);
    } else {
      return _AddWarranty(loansState: loansState);
    }
  }
}

class _AddWarranty extends StatelessWidget {
  const _AddWarranty({
    required this.loansState,
  });
  final LoansStepState loansState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Marca',
                initialValue: loansState.brand,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeBrand(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Modelo',
                initialValue: loansState.model,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeModel(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Color',
                initialValue: loansState.color,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeColor(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Estado',
                initialValue: loansState.status,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeStatus(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Serie',
          initialValue: loansState.serie,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangeSerie(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Observaciones',
          initialValue: loansState.warrantyObservations,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangeWarrantyObservations(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Precio Referencial',
          initialValue: loansState.price,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangePrice(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        if (loansState.listWarranty == null ||
            loansState.listWarranty!.isEmpty) ...[
          SecondaryButton(
            onPressed: () => context.read<LoansStepBloc>().add(
                  const ChangeIndexLoans(
                    index: 1,
                  ),
                ),
            child: Text('Volver'),
          ),
          const SizedBox(height: 15),
        ],
        PrimaryButton(
          onPressed: loansState.canRegisterWarranty
              ? () {
                  if (loansState.idWarranty == null) {
                    context.read<LoansStepBloc>().add(
                          AddListWarranty(
                            value: Warranty(
                              id: generateIDFromDateTime(),
                              brand: loansState.brand,
                              model: loansState.model,
                              color: loansState.color,
                              status: loansState.status,
                              serie: loansState.serie,
                              warrantyObservations:
                                  loansState.warrantyObservations,
                              price: loansState.price,
                            ),
                          ),
                        );
                  } else {
                    context.read<LoansStepBloc>().add(
                          EditListWarranty(
                            value: Warranty(
                              id: loansState.idWarranty,
                              brand: loansState.brand,
                              model: loansState.model,
                              color: loansState.color,
                              status: loansState.status,
                              serie: loansState.serie,
                              warrantyObservations:
                                  loansState.warrantyObservations,
                              price: loansState.price,
                            ),
                          ),
                        );
                  }
                }
              : null,
          child: Text(loansState.idWarranty == null ? 'Guardar' : 'Editar'),
        )
      ],
    );
  }
}

class _ListWarranty extends StatelessWidget {
  const _ListWarranty({
    required this.loansState,
  });
  final LoansStepState loansState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          shrinkWrap: true,
          itemCount: loansState.listWarranty!.length,
          itemBuilder: (context, index) {
            final warranty = loansState.listWarranty![index];
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
                Text('Modelo: ${warranty.model}'),
                Text('Marca: ${warranty.brand}'),
                Text('Color: ${warranty.color}'),
                Text('Estado: ${warranty.status}'),
                Text('Serie: ${warranty.serie}'),
                Text('Observaciones: ${warranty.warrantyObservations}'),
                Text('Precio Referencial: ${warranty.price}'),
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
          onPressed: loansState.listWarranty != null
              ? () {
                  print('asdasd');
                  context.read<LoansStepBloc>().add(
                        AddListWarranty(
                          value: Warranty(
                            id: generateIDFromDateTime(),
                            brand: loansState.brand,
                            model: loansState.model,
                            color: loansState.color,
                            status: loansState.status,
                            serie: loansState.serie,
                            warrantyObservations:
                                loansState.warrantyObservations,
                            price: loansState.price,
                          ),
                        ),
                      );
                }
              : null,
          child: Text('Registrar Préstamo'),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
