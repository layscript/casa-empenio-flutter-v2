import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/escaner_bien.dart';
import 'package:flutter/material.dart';

class SearchDTO {
  final String? text;
  final String? category;

  const SearchDTO({
    this.text,
    this.category,
  });
}

class SearchLoansClientByGeneral extends StatefulWidget {
  const SearchLoansClientByGeneral({
    super.key,
    required this.categories,
    required this.onPressed,
  });
  final List<CategoriesEntity> categories;
  final void Function(SearchDTO)? onPressed;

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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (textCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => textCtrl.clear()),
                        child: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: 'Buscar tomando foto (serie, modelo, placa o IMEI)',
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: () async {
                        final r = await capturarCampo(context, campo: 'serie', tipo: 'OTRO');
                        if (r == null || r.valor.isEmpty) return;
                        setState(() {
                          textCtrl.text = r.valor;
                          textIsValid = true;
                        });
                        widget.onPressed?.call(SearchDTO(
                          category: selectedCategory?.descripcion,
                          text: r.valor,
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                /* onPressed: textIsValid || selectedCategory != null
                    ? () {
                        context.read<LoansBloc>().add(
                              GetLoansByText(
                                criterio: textCtrl.text,
                                categoria: selectedCategory?.descripcion,
                              ),
                            );
                      }
                    : null, */
                onPressed: textIsValid || selectedCategory != null
                    ? () {
                        widget.onPressed!(SearchDTO(
                          category: selectedCategory?.descripcion,
                          text: textCtrl.text,
                        ));
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
