part of '../contract_reports_body_view.dart';

class _ListCategories extends StatelessWidget {
  const _ListCategories({
    required this.constraints,
    required this.state,
    required this.reportsBloc,
  });
  final BoxConstraints constraints;
  final ReportsState state;
  final ReportsBloc reportsBloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.purple,
      margin: const EdgeInsets.only(top: 5),
      height: constraints.maxHeight * 0.05,
      width: double.infinity,
      child: DropdownButton<CategoriesEntity?>(
        underline: const SizedBox(),
        isDense: true,
        hint: const Text('Seleccione una categoria'),
        value: state.selectedCategory,
        items: state.listCategories
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e.descripcion),
              ),
            )
            .toList(),
        onChanged: (value) {
          reportsBloc.add(
            ChangeCategoryEvent(value),
          );
        },
      ),
    );
  }
}
