import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class AppDropdownButtonFormField<T> extends StatelessWidget {
  const AppDropdownButtonFormField({
    Key? key,
    this.value,
    required this.onChanged,
    required this.items,
    this.labelText,
    this.decoration,
    this.selectedItemBuilder,
    this.iconPadding,
    this.icon,
    this.colorIconSize,
  }) : super(key: key);
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<DropdownMenuItem<T>>? items;
  final String? labelText;
  final InputDecoration? decoration;
  final DropdownButtonBuilder? selectedItemBuilder;
  final EdgeInsets? iconPadding;
  final Widget? icon;
  final Color? colorIconSize;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      onChanged: onChanged,
      menuMaxHeight: 300,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.secondaryText,
      ),
      icon: icon ??
          Padding(
            padding: iconPadding ?? const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
                /* child: ImageIcon(
                const AssetImage(AppIcons.chevronDown),
                size: _iconSize,
                color: colorIconSize ?? AppColors.secondaryText,
              ), */
                ),
          ),
      iconSize: 0,
      items: items,
      decoration: decoration ??
          InputDecoration(
            prefixIconConstraints: const BoxConstraints(),
            /* prefixIcon: prefixIconBlue
                ? Container(
                    margin: const EdgeInsets.only(
                      left: 10,
                      right: 5,
                    ),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      //color: AppColors.inputFocus,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      //color: AppColors.primary,
                      size: 23,
                    ),
                  )
                : null, */
            suffixIconConstraints: const BoxConstraints(),
            /* suffixIcon: suffixIconBlue
                ? Container(
                    margin: const EdgeInsets.only(
                      left: 5,
                      right: 10,
                    ),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      //color: AppColors.inputFocus,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      //color: AppColors.primary,
                      size: 23,
                    ),
                  )
                : null, */
            labelText: labelText,
            hintText: labelText,
            filled: true,
            isDense: true,
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.secondaryText,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.secondaryText,
              ),
            ),
            fillColor: AppColors.white,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.secondaryText,
              ),
            ),
            constraints: const BoxConstraints(
              maxHeight: 53.3,
              minHeight: 53.3,
            ),
          ),
      selectedItemBuilder: selectedItemBuilder,
    );
  }
}
