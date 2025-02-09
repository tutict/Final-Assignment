// 导入所需包和库
import 'package:chinese_font_library/chinese_font_library.dart';
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
            },
            data: data,
          ),
        );
      }).toList(),
    );
  }
}

void navigateToPage(String routeName) {
  Get.toNamed(routeName);
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
    // 获取当前主题亮度，判断是否为亮色模式
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    // 根据当前状态设置背景色：
    // 未选中状态：亮色模式下使用白色，暗色模式下使用卡片背景色
    // 选中状态：在亮色模式下使用 primaryColor 的浅色透明效果，
    //           在暗色模式下可以稍微加深透明度以提高对比度
    final Color backgroundColor = !selected
        ? (isLight ? Colors.white : Theme.of(context).cardColor)
        : (isLight
            ? Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt())
            : Theme.of(context).primaryColor.withAlpha((0.2 * 255).toInt()));

    // 阴影颜色，根据选中状态和当前主题调整
    final Color shadowColor = selected
        ? (isLight
            ? Colors.blueAccent.withAlpha((0.3 * 255).toInt())
            : Colors.black87.withAlpha((0.3 * 255).toInt()))
        : (isLight ? Colors.black12 : Colors.black26);

    // 未选中时图标和文字颜色：
    // 在亮色模式下使用较深色（例如 Colors.black87），暗色模式下使用白色
    final Color defaultIconColor = !selected
        ? (isLight ? Colors.black87 : Colors.white70)
        : Theme.of(context).primaryColor;
    final Color defaultTextColor = !selected
        ? (isLight ? Colors.black87 : Colors.white70)
        : Theme.of(context).primaryColor;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 6.0 : 3.0,
      shadowColor: shadowColor,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor:
            Theme.of(context).primaryColor.withAlpha((0.2 * 255).toInt()),
        child: Padding(
          padding: const EdgeInsets.all(kSpacing),
          child: Row(
            children: [
              _icon(
                  data: (!selected) ? data.icon : data.activeIcon,
                  color: defaultIconColor),
              const SizedBox(width: kSpacing / 2),
              Expanded(child: _labelText(data.label, color: defaultTextColor)),
              if (data.totalNotif != null)
                Padding(
                  padding: const EdgeInsets.only(left: kSpacing / 2),
                  child: _notif(total: data.totalNotif!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 渲染按钮图标，传入自定义颜色
  Widget _icon({required IconData data, required Color color}) {
    return Icon(
      data,
      size: 24,
      color: color,
    );
  }

  // 渲染按钮标签文本，传入自定义颜色
  Widget _labelText(String text, {required Color color}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        fontSize: 15,
      ).useSystemChineseFont(),
    );
  }

  // 渲染通知数标记
  Widget _notif({required int total}) {
    if (total <= 0) return Container();
    return Container(
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
