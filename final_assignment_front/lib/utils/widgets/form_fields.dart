import 'dart:async';

import 'package:flutter/material.dart';

typedef AppAutocompleteOptionsBuilder<T extends Object> = FutureOr<Iterable<T>>
    Function(String query);

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.readOnly = false,
    this.showClear = false,
    this.onClear,
    this.keyboardType,
    this.maxLines = 1,
    this.suffix,
    this.prefixIcon,
    this.prefixText,
    this.helperText,
    this.hintText,
    this.onTap,
    this.onChanged,
    this.maxLength,
    this.fillColor,
    this.readOnlyFillColor,
    this.borderless = false,
    this.contentPadding,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final bool showClear;
  final VoidCallback? onClear;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffix;
  final IconData? prefixIcon;
  final String? prefixText;
  final String? helperText;
  final String? hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final Color? fillColor;
  final Color? readOnlyFillColor;
  final bool borderless;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller == null) {
      return TextFormField(
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: _decoration(theme, false),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, child) => TextFormField(
        controller: controller,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: _decoration(theme, value.text.isNotEmpty),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _decoration(ThemeData theme, bool hasText) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      helperText: helperText,
      helperStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: theme.colorScheme.primary),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: borderless ? BorderSide.none : const BorderSide(),
      ),
      enabledBorder: borderless
          ? null
          : OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
      focusedBorder: borderless
          ? null
          : OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
      filled: true,
      fillColor: readOnly
          ? readOnlyFillColor ??
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : fillColor ?? theme.colorScheme.surfaceContainerLowest,
      suffixIcon: _suffixIcon(theme, hasText),
      contentPadding: contentPadding,
    );
  }

  Widget? _suffixIcon(ThemeData theme, bool hasText) {
    if (suffix != null) return suffix;
    if (!showClear || !hasText || controller == null) return null;
    return IconButton(
      icon: Icon(Icons.clear, color: theme.colorScheme.onSurfaceVariant),
      onPressed: onClear ?? controller!.clear,
    );
  }
}

class AppAutocompleteField<T extends Object> extends StatelessWidget {
  const AppAutocompleteField({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.controller,
    this.displayStringForOption,
    this.validator,
    this.keyboardType,
    this.maxLength,
    this.helperText,
    this.onChanged,
    this.onClear,
    this.optionsMaxHeight = 200,
    this.optionsMaxWidth = 300,
  });

  final String label;
  final AppAutocompleteOptionsBuilder<T> options;
  final ValueChanged<T> onSelected;
  final TextEditingController? controller;
  final AutocompleteOptionToString<T>? displayStringForOption;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double optionsMaxHeight;
  final double optionsMaxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Autocomplete<T>(
      displayStringForOption: _displayStringForOption,
      optionsBuilder: (textEditingValue) async {
        return options(textEditingValue.text);
      },
      onSelected: (selection) {
        controller?.text = _displayStringForOption(selection);
        onSelected(selection);
      },
      fieldViewBuilder: (context, textController, focusNode, _) {
        if (controller != null && controller!.text != textController.text) {
          textController.value = TextEditingValue(
            text: controller!.text,
            selection: TextSelection.collapsed(offset: controller!.text.length),
          );
        }

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: textController,
          builder: (context, value, child) {
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                    TextStyle(color: theme.colorScheme.onSurfaceVariant),
                helperText: helperText,
                helperStyle: TextStyle(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          textController.clear();
                          controller?.clear();
                          onClear?.call();
                        },
                      )
                    : null,
              ),
              keyboardType: keyboardType,
              maxLength: maxLength,
              validator: validator,
              onChanged: (value) {
                controller?.text = value;
                onChanged?.call(value);
              },
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: optionsMaxHeight,
                maxWidth: optionsMaxWidth,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      _displayStringForOption(option),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayStringForOption(T option) {
    return displayStringForOption?.call(option) ?? option.toString();
  }
}
