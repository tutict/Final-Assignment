import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

class SearchField extends StatelessWidget {
  SearchField({this.onSearch, super.key});

  final controller = TextEditingController();
  final Function(String value)? onSearch;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(EvaIcons.search),
        hintText: "搜索..",
        isDense: true,
        fillColor: Theme.of(context).cardColor,
      ),
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        if (onSearch != null) onSearch!(controller.text);
      },
      textInputAction: TextInputAction.search,
      style: TextStyle(color: kFontColorPallets[1]).useSystemChineseFont(),
    );
  }
}
