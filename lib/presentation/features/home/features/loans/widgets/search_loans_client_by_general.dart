import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchLoansClientByGeneral extends StatefulWidget {
  const SearchLoansClientByGeneral({
    super.key,
    required this.categories,
  });
  final List<CategoriesEntity> categories;

  @override
  State<SearchLoansClientByGeneral> createState() =>
      _SearchLoansClientByGeneralState();
}

class _SearchLoansClientByGeneralState
    extends State<SearchLoansClientByGeneral> {
  final textCtrl = TextEditingController();
  bool textIsValid = false;

  CategoriesEntity? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextFormField(
                controller: textCtrl,
                labelText: 'Ingresar texto',
                isValid: (value) => setState(() => textIsValid = value),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  return null;
                },
                suffixIcon: textCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          textCtrl.clear();
                          context.read<LoansBloc>().add(GetLoansInitial());
                        },
                        child: const Icon(
                          Icons.clear,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: textIsValid || selectedCategory != null
                    ? () {
                        context.read<LoansBloc>().add(
                              GetLoansByText(
                                criterio: textCtrl.text,
                                categoria: selectedCategory?.descripcion,
                              ),
                            );
                      }
                    : null,
                child: const Text('Buscar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppDropdownButtonFormField<CategoriesEntity?>(
          labelText: 'Filtrar por Categoría',
          value: selectedCategory,
          onChanged: (value) {
            setState(() {
              selectedCategory = value;
            });
          },
          suffixOnPressed: () {
            setState(() {
              selectedCategory = null;
            });
          },
          items: widget.categories
              .map(
                (category) => DropdownMenuItem<CategoriesEntity?>(
                  value: category,
                  child: Text(category.descripcion),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
