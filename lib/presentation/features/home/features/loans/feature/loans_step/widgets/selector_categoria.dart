import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dos pasos claros: 1) Categoría  2) Subcategoría (solo si la categoría tiene).
/// Guarda en el bloc la subcategoría si se eligió, o la categoría si no.
class SelectorCategoria extends StatelessWidget {
  const SelectorCategoria({super.key});

  InputDecoration _deco(String label, String ayuda, IconData icono) {
    return InputDecoration(
      labelText: label,
      helperText: ayuda,
      helperMaxLines: 2,
      prefixIcon: Icon(icono, size: 20),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LoansStepBloc>();
    return BlocBuilder<LoansStepBloc, LoansStepState>(
      buildWhen: (a, b) =>
          a.categories != b.categories || a.listCategories != b.listCategories,
      builder: (context, state) {
        final todas = state.listCategories;
        if (todas == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }
        final ids = todas.map((e) => e.id).toSet();
        final raices = todas
            .where((c) => c.padreId == null || !ids.contains(c.padreId))
            .toList()
          ..sort((a, b) => a.descripcion
              .toLowerCase()
              .compareTo(b.descripcion.toLowerCase()));

        final elegida = state.categories;
        CategoriesEntity? principal;
        CategoriesEntity? sub;
        if (elegida != null) {
          if (elegida.padreId != null && ids.contains(elegida.padreId)) {
            principal = todas.firstWhere((c) => c.id == elegida.padreId);
            sub = todas.firstWhere((c) => c.id == elegida.id);
          } else {
            principal = todas.firstWhere(
              (c) => c.id == elegida.id,
              orElse: () => elegida,
            );
          }
        }
        final subs = principal == null
            ? <CategoriesEntity>[]
            : (todas.where((c) => c.padreId == principal!.id).toList()
              ..sort((a, b) => a.descripcion
                  .toLowerCase()
                  .compareTo(b.descripcion.toLowerCase())));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              value: principal != null && raices.any((r) => r.id == principal!.id)
                  ? principal.id
                  : null,
              isExpanded: true,
              menuMaxHeight: 360,
              decoration: _deco(
                '1. Categoría (requerido)',
                'Elige el tipo de bien: celular, terreno, vehículo...',
                Icons.category_outlined,
              ),
              items: raices
                  .map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.descripcion,
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                bloc.add(ChangeCategoryWarranty(
                    todas.firstWhere((c) => c.id == id)));
              },
            ),
            if (subs.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: sub?.id,
                isExpanded: true,
                menuMaxHeight: 360,
                decoration: _deco(
                  '2. Subcategoría (opcional)',
                  'Hay ${subs.length} opciones dentro de ${principal!.descripcion}',
                  Icons.subdirectory_arrow_right,
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Solo ${principal.descripcion} (general)',
                        overflow: TextOverflow.ellipsis),
                  ),
                  ...subs.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.descripcion,
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (id) {
                  final p = principal!;
                  bloc.add(ChangeCategoryWarranty(
                      id == null ? p : todas.firstWhere((c) => c.id == id)));
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
