import 'package:final_assignment_front/shared/eva_icons_compat.dart';
import 'package:flutter/material.dart';

/// SearchField 是一个自定义搜索字段，支持外部搜索回调
class SearchField extends StatelessWidget {
  SearchField({this.onSearch, super.key});

  final controller = TextEditingController();
  final Function(String value)? onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 50,
          maxHeight: 56,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: scheme.surface.withValues(alpha: dark ? 0.92 : 0.98),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: dark ? 0.45 : 0.58),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: dark ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.48),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: scheme.primary.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              EvaIcons.search,
              color: scheme.onSurfaceVariant,
              size: 24,
            ),
            hintText: "请输入...",
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 18.0,
              bottom: 14.0,
            ),
            isDense: false,
            alignLabelWithHint: true,
          ),
          textAlignVertical: const TextAlignVertical(y: -0.2),
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
            if (onSearch != null) onSearch!(controller.text);
          },
          textInputAction: TextInputAction.search,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
