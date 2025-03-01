part of '../manager_screens/manager_dashboard_screen.dart';

class _TeamMember extends StatelessWidget {
  const _TeamMember({
    required this.totalMember,
    required this.onPressedAdd,
  });

  final int totalMember;
  final Function() onPressedAdd;

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    // 确保亮色模式下使用深色文字，暗色模式下使用浅色文字
    final Color primaryTextColor = isLight
        ? Colors.black87 // 亮色模式：深黑色，确保与白色背景对比
        : Colors.white; // 暗色模式：白色，确保与暗色背景对比
    final Color secondaryTextColor = isLight
        ? Colors.grey[600]! // 亮色模式：深灰色
        : Colors.grey[400]!; // 暗色模式：浅灰色

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 确保两端对齐
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // 增大字体大小，确保清晰可见
                  color: primaryTextColor, // 动态调整为主文本颜色
                )
                .useSystemChineseFont(),
            children: [
              const TextSpan(text: "其他管理员"),
              TextSpan(
                text: "($totalMember)",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 14, // 略小字体，用于辅助信息
                      color: secondaryTextColor, // 动态调整为辅助文本颜色
                    )
                    .useSystemChineseFont(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16), // 添加间距，增强布局整齐度
        IconButton(
          onPressed: onPressedAdd,
          icon: Icon(
            EvaIcons.plus,
            color: primaryTextColor, // 使用与主文本相同的颜色，确保一致性
          ),
          tooltip: "添加成员",
          iconSize: 24,
          // 增大图标大小，增强可点击性
          padding: const EdgeInsets.all(8),
          // 调整内边距，使图标更紧凑
        ),
      ],
    );
  }
}
