import 'dart:async';

import 'package:flutter/material.dart';

class SearchFilterOption {
  const SearchFilterOption({
    required this.value,
    required this.label,
    this.hintText,
  });

  final String value;
  final String label;
  final String? hintText;
}

typedef SearchSuggestionsBuilder = FutureOr<Iterable<String>> Function(
  String query,
);

typedef DateRangeTextBuilder = String Function(DateTime start, DateTime end);

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.onSearch,
    this.controller,
    this.searchTypes,
    this.selectedSearchType,
    this.onTypeChanged,
    this.suggestions,
    this.showDateRange = false,
    this.onDateRangeChanged,
    this.hintText,
    this.onClear,
    this.onChanged,
    this.onSubmitted,
    this.onSelected,
    this.searchEnabled = true,
    this.clearButtonIncludesDateRange = false,
    this.startDate,
    this.endDate,
    this.dateRangeTextBuilder,
    this.dateRangePlaceholder = '选择日期范围',
    this.dateRangeTooltip = '按日期范围搜索',
    this.clearDateRangeTooltip = '清除日期范围',
    this.dateRangeHelpText = '选择日期范围',
    this.firstDate,
    this.lastDate,
    this.wrapInCard = false,
    this.cardElevation = 4,
    this.cardBorderRadius = 16,
    this.cardColor,
    this.cardPadding = const EdgeInsets.all(12),
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.inputBorderRadius = 12,
    this.inputBorderless = false,
    this.fillColor,
  });

  final ValueChanged<String> onSearch;
  final TextEditingController? controller;
  final List<SearchFilterOption>? searchTypes;
  final String? selectedSearchType;
  final ValueChanged<String>? onTypeChanged;
  final SearchSuggestionsBuilder? suggestions;
  final bool showDateRange;
  final ValueChanged<DateTimeRange?>? onDateRangeChanged;
  final String? hintText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onSelected;
  final bool searchEnabled;
  final bool clearButtonIncludesDateRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateRangeTextBuilder? dateRangeTextBuilder;
  final String dateRangePlaceholder;
  final String dateRangeTooltip;
  final String clearDateRangeTooltip;
  final String dateRangeHelpText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool wrapInCard;
  final double cardElevation;
  final double cardBorderRadius;
  final Color? cardColor;
  final EdgeInsetsGeometry cardPadding;
  final EdgeInsetsGeometry padding;
  final double inputBorderRadius;
  final bool inputBorderless;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDateRange = startDate != null && endDate != null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SearchAutocompleteField(
                controller: controller,
                enabled: searchEnabled,
                hintText: _resolvedHintText(),
                showClearForDateRange:
                    clearButtonIncludesDateRange && hasDateRange,
                suggestions: suggestions,
                inputBorderRadius: inputBorderRadius,
                inputBorderless: inputBorderless,
                fillColor: fillColor,
                onChanged: onChanged ?? onSearch,
                onSubmitted: onSubmitted ?? onSearch,
                onSelected: onSelected ?? onSearch,
                onClear: () {
                  controller?.clear();
                  if (onClear != null) {
                    onClear!();
                  } else {
                    onSearch('');
                  }
                },
              ),
            ),
            if (searchTypes != null && searchTypes!.isNotEmpty) ...[
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedSearchType,
                onChanged: (value) {
                  if (value != null) onTypeChanged?.call(value);
                },
                items: searchTypes!
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                dropdownColor: theme.colorScheme.surfaceContainer,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        if (showDateRange && onDateRangeChanged != null) ...[
          const SizedBox(height: 8),
          DateRangeFilter(
            startDate: startDate,
            endDate: endDate,
            textBuilder: dateRangeTextBuilder,
            placeholder: dateRangePlaceholder,
            tooltip: dateRangeTooltip,
            clearTooltip: clearDateRangeTooltip,
            helpText: dateRangeHelpText,
            firstDate: firstDate,
            lastDate: lastDate,
            onChanged: onDateRangeChanged!,
          ),
        ],
      ],
    );

    final padded = Padding(
      padding: wrapInCard ? cardPadding : padding,
      child: content,
    );

    if (!wrapInCard) {
      return padded;
    }

    return Card(
      elevation: cardElevation,
      color: cardColor ?? theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      child: padded,
    );
  }

  String? _resolvedHintText() {
    if (hintText != null) return hintText;
    if (searchTypes == null || searchTypes!.isEmpty) return null;
    for (final option in searchTypes!) {
      if (option.value == selectedSearchType) {
        return option.hintText;
      }
    }
    return searchTypes!.first.hintText;
  }
}

class DateRangeFilter extends StatelessWidget {
  const DateRangeFilter({
    super.key,
    required this.onChanged,
    this.startDate,
    this.endDate,
    this.textBuilder,
    this.placeholder = '选择日期范围',
    this.tooltip = '按日期范围搜索',
    this.clearTooltip = '清除日期范围',
    this.helpText = '选择日期范围',
    this.firstDate,
    this.lastDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final DateRangeTextBuilder? textBuilder;
  final String placeholder;
  final String tooltip;
  final String clearTooltip;
  final String helpText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTimeRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRange = startDate != null && endDate != null;

    return Row(
      children: [
        Expanded(
          child: Text(
            hasRange
                ? textBuilder?.call(startDate!, endDate!) ??
                    '${startDate!.toLocal()} 至 ${endDate!.toLocal()}'
                : placeholder,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasRange
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.date_range, color: theme.colorScheme.primary),
          tooltip: tooltip,
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: firstDate ?? DateTime(2000),
              lastDate: lastDate ?? DateTime.now(),
              initialDateRange: hasRange
                  ? DateTimeRange(start: startDate!, end: endDate!)
                  : null,
              locale: const Locale('zh', 'CN'),
              helpText: helpText,
              cancelText: '取消',
              confirmText: '确定',
              fieldStartHintText: '开始日期',
              fieldEndHintText: '结束日期',
              builder: (context, child) {
                return Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: theme.colorScheme.primary,
                      onPrimary: theme.colorScheme.onPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
        ),
        if (hasRange)
          IconButton(
            icon: Icon(
              Icons.clear,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: clearTooltip,
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}

class _SearchAutocompleteField extends StatelessWidget {
  const _SearchAutocompleteField({
    required this.enabled,
    required this.hintText,
    required this.showClearForDateRange,
    required this.suggestions,
    required this.inputBorderRadius,
    required this.inputBorderless,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSelected,
    required this.onClear,
    this.controller,
    this.fillColor,
  });

  final TextEditingController? controller;
  final bool enabled;
  final String? hintText;
  final bool showClearForDateRange;
  final SearchSuggestionsBuilder? suggestions;
  final double inputBorderRadius;
  final bool inputBorderless;
  final Color? fillColor;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) async {
        if (!enabled || textEditingValue.text.isEmpty || suggestions == null) {
          return const Iterable<String>.empty();
        }
        return await suggestions!(textEditingValue.text);
      },
      onSelected: (selection) {
        controller?.text = selection;
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
            return TextField(
              controller: textController,
              focusNode: focusNode,
              enabled: enabled,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: value.text.isNotEmpty || showClearForDateRange
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          textController.clear();
                          onClear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(inputBorderRadius),
                  borderSide:
                      inputBorderless ? BorderSide.none : const BorderSide(),
                ),
                enabledBorder: inputBorderless
                    ? null
                    : OutlineInputBorder(
                        borderRadius: BorderRadius.circular(inputBorderRadius),
                        borderSide: BorderSide(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                focusedBorder: inputBorderless
                    ? null
                    : OutlineInputBorder(
                        borderRadius: BorderRadius.circular(inputBorderRadius),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                filled: true,
                fillColor: fillColor ??
                    (inputBorderless
                        ? theme.colorScheme.surfaceContainer
                        : theme.colorScheme.surfaceContainerLowest),
                contentPadding: EdgeInsets.symmetric(
                  vertical: inputBorderless ? 14 : 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                controller?.text = value;
                onChanged(value);
              },
              onSubmitted: (value) {
                controller?.text = value;
                onSubmitted(value);
              },
            );
          },
        );
      },
    );
  }
}
