// 导入所需包和库
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    // 未选中时背景色为透明，选中时使用 primaryColor 的浅透明效果
    final Color backgroundColor = selected
        ? Theme.of(context).primaryColor.withValues(alpha: isLight ? 0.15 : 0.25)
        : Colors.transparent;

    // 阴影颜色，根据选中状态调整
    final Color shadowColor =
        isLight ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.3);

    // 图标和文字颜色
    final Color defaultIconColor = selected
        ? Theme.of(context).primaryColor
        : Theme.of(context).iconTheme.color!;
    final Color defaultTextColor = selected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyLarge!.color!;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 4.0 : 0.0,
      // 选中时增加阴影
      shadowColor: shadowColor,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        // 增强涟漪效果
        highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        // 添加高亮反馈
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          // 增加内边距
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _icon(
                  data: selected ? data.activeIcon : data.icon,
                  color: defaultIconColor),
              const SizedBox(width: 12.0), // 增加图标与文字间距
              Expanded(child: _labelText(data.label, color: defaultTextColor)),
              if (data.totalNotif != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
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
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500, // 选中时加粗
        letterSpacing: 0.5, // 减小字符间距
        fontSize: 16, // 增大字体
      ),
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
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
