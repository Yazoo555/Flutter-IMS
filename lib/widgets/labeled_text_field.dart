import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LabeledTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction; // Added textInputAction parameter
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final int? maxLength;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction, // Added textInputAction
    this.prefixIcon,
    this.validator,
    this.maxLength,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTheme.labelSmall(context)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction, // Added textInputAction
          validator: widget.validator,
          maxLength: widget.maxLength,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.getTextPrimary(context),
            fontWeight: FontWeight.w500,
          ),
          decoration: AppTheme.inputDecoration(
            context: context,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: widget.prefixIcon,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.getTextHint(context),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
