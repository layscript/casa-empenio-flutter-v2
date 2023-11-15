import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _iconSize = 24.0;

class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    Key? key,
    this.onChanged,
    required this.labelText,
    this.obscureText = false,
    this.controller,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.initialValue,
    this.validator,
    this.isValid,
    this.inputFormatters,
    this.inputStyle,
  }) : super(key: key);
  final void Function(String)? onChanged;
  final String labelText;
  final bool obscureText;
  final TextEditingController? controller;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<bool>? isValid;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? inputStyle;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  late FocusNode _focusNode;
  bool _hasError = false;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(focusListener);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(focusListener)
      ..dispose();
    super.dispose();
  }

  void focusListener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: widget.initialValue,
      controller: widget.controller,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.labelText,
        counterText: '',
        suffixIconConstraints: const BoxConstraints(
          maxWidth: _iconSize + 30,
        ),
        prefixIconConstraints: const BoxConstraints(
          maxWidth: _iconSize + 30,
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondaryText),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: _focusNode.hasFocus
              ? _hasError
                  ? AppColors.error
                  : AppColors.buttonPrimary
              : _hasError
                  ? AppColors.error
                  : AppColors.secondaryText,
        ),
      ),
      validator: (value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final result = widget.validator?.call(value);
          setState(() {
            _hasError = result != null;
          });
          widget.isValid?.call(result == null);
        });
        return widget.validator?.call(value);
      },
      autocorrect: false,
      enableSuggestions: false,
      obscuringCharacter: '*',
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.keyboardType == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      style: widget.inputStyle ??
          const TextStyle(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
    );
  }
}
