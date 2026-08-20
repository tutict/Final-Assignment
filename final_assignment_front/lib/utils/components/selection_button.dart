// 导入所需包和库
import 'package:flutter/material.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';

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
          child: _SelectionOptionButton(
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
  NavigationHelper.toNamed(routeName);
}

// 定义实际渲染的按钮组件
class _SelectionOptionButton extends StatelessWidget {
  const _SelectionOptionButton({
    required this.selected,
    required this.data,
    required this.onPressed,
  });

  final bool selected;
  final SelectionButtonData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color backgroundColor = selected
        ? scheme.primary.withValues(alpha: 0.15)
        : Colors.transparent;

    final Color defaultIconColor = selected
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final Color defaultTextColor = selected
        ? scheme.primary
        : scheme.onSurface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      elevation: selected ? 0.0 : 0.0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        splashColor: scheme.primary.withValues(alpha: 0.3),
        highlightColor: scheme.primary.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _icon(
                  data: selected ? data.activeIcon : data.icon,
                  color: defaultIconColor),
              const SizedBox(width: 12.0),
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

  Widget _labelText(String text, {required Color color}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: 0,
        fontSize: 16,
      ),
    );
  }

  Widget _notif({required int total}) {
    if (total <= 0) return Container();
    return Container(
      width: 30,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kNotifColor,
        borderRadius: BorderRadius.circular(8),
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
