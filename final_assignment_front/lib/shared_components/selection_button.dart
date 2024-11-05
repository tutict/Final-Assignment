// 导入所需包和库
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:get/get.dart';

// 定义选择按钮的数据模型，包含图标、标签和回调函数等信息
class SelectionButtonData {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final int? totalNotif;
  final String routeName;

  SelectionButtonData({
    required this.activeIcon,
    required this.icon,
    required this.label,
    this.totalNotif,
    required this.routeName,
  });
}

// 定义一个可状态化的选择按钮组件
class SelectionButton extends StatefulWidget {
  const SelectionButton({
    this.initialSelected = 0,
    required this.data,
    required this.onSelected,
    super.key,
  });

  final int initialSelected;
  final List<SelectionButtonData> data;
  final Function(int index, SelectionButtonData value) onSelected;

  @override
  State<SelectionButton> createState() => _SelectionButtonState();
}

// 定义选择按钮的状态
class _SelectionButtonState extends State<SelectionButton> {
  late int selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.data.asMap().entries.map((e) {
        final index = e.key;
        final data = e.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: _Button(
            selected: selected == index,
            onPressed: () {
              widget.onSelected(index, data);
              setState(() {
                selected = index;
              });
              final route = AppPages.routes.firstWhere(
                (route) => route.name == data.routeName,
                orElse: () => GetPage(name: '/', page: () => const Scaffold()),
              );
              if (route.name.isNotEmpty) {
                Get.toNamed(route.name);
              }
            },
            data: data,
          ),
        );
      }).toList(),
    );
  }
}

// 定义实际渲染的按钮组件
class _Button extends StatelessWidget {
  const _Button({
    required this.selected,
    required this.data,
    required this.onPressed,
  });

  final bool selected;
  final SelectionButtonData data;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (!selected)
          ? Theme.of(context).cardColor
          : Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 6.0 : 3.0,
      shadowColor:
          selected ? Colors.blueAccent.withAlpha((0.3 * 255).toInt()) : Colors.black12,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).primaryColor.withAlpha((0.2 * 255).toInt()),
        child: Padding(
          padding: const EdgeInsets.all(kSpacing),
          child: Row(
            children: [
              _icon((!selected) ? data.icon : data.activeIcon),
              const SizedBox(width: kSpacing / 2),
              Expanded(child: _labelText(data.label)),
              if (data.totalNotif != null)
                Padding(
                  padding: const EdgeInsets.only(left: kSpacing / 2),
                  child: _notif(data.totalNotif!),
                )
            ],
          ),
        ),
      ),
    );
  }

  // 渲染按钮图标
  Widget _icon(IconData iconData) {
    return Icon(
      iconData,
      size: 24,
      color: (!selected)
          ? kFontColorPallets[2]
          : Theme.of(Get.context!).primaryColor,
    );
  }

  // 渲染按钮标签文本
  Widget _labelText(String data) {
    return Text(
      data,
      style: TextStyle(
        color: (!selected)
            ? kFontColorPallets[1]
            : Theme.of(Get.context!).primaryColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        fontSize: 15,
      ).useSystemChineseFont(),
    );
  }

  // 渲染通知数标记
  Widget _notif(int total) {
    return (total <= 0)
        ? Container()
        : Container(
            width: 30,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: kNotifColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              (total >= 100) ? "99+" : "$total",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ).useSystemChineseFont(),
              textAlign: TextAlign.center,
            ),
          );
  }
}
