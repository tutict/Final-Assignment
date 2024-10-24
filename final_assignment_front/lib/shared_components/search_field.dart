import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

/// SearchField是一个自定义搜索字段，支持外部搜索回调
/// 它包含一个文本字段，用户可以在其中输入以完成搜索操作
/// 参数:
///   - onSearch: 一个可选的回调函数，当用户完成编辑时，如果提供了这个函数，就会用文本字段的值调用它
/// 优化后的搜索字段组件，使其更加现代化和美观
class SearchField extends StatelessWidget {
  /// 构造函数接受一个搜索回调
  SearchField({this.onSearch, super.key});

  /// 控制文本字段的文本控制器
  final controller = TextEditingController();

  /// 搜索回调函数，当用户完成搜索操作时调用，传递搜索文本
  final Function(String value)? onSearch;

  /// 构建搜索字段的UI
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: TextField(
          controller: controller,

          /// 装饰文本字段以使其更美观
          decoration: InputDecoration(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(
              EvaIcons.search,
              color: Colors.grey,
            ),
            hintText: "搜索...",
            hintStyle: TextStyle(color: Colors.grey.shade600),
            isDense: true,
            fillColor: Colors.transparent,
          ),

          /// 当用户完成编辑时，取消焦点并触发搜索回调
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
            if (onSearch != null) onSearch!(controller.text);
          },
          textInputAction: TextInputAction.search,

          /// 设置文本字段的样式，并使用系统中文字体
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ).useSystemChineseFont(),
        ),
      ),
    );
  }
}
