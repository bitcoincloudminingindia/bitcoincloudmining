import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final String? errorText;
  final Function(String)? onChanged;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? floatingLabelStyle;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? backgroundColor;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.prefixIconColor,
    this.errorText,
    this.onChanged,
    this.textStyle,
    this.labelStyle,
    this.floatingLabelStyle,
    this.borderColor,
    this.focusedBorderColor,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: textStyle,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefix: prefix,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: prefixIconColor ?? Colors.white70)
            : null,
        suffixIcon: suffix,
        errorText: errorText,
        labelStyle: labelStyle,
        floatingLabelStyle: floatingLabelStyle,
        filled: backgroundColor != null,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: borderColor ?? Colors.white70,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: borderColor ?? Colors.white70,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: focusedBorderColor ?? Colors.blue[400]!,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
