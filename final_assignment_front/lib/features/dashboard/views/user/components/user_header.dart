part of '../user_dashboard.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // TodayText 宽度占屏幕宽度的 25%
        final double todayTextWidth = maxWidth * 0.25;
        final double clampedTodayTextWidth =
            (todayTextWidth - 38.0).clamp(80.0, 262.0);

        // 动态调整字体大小
        final double locationFontSize =
            (10.0 + (maxWidth - 300) / 100).clamp(10.0, 14.0);
        final double dateFontSize =
            (8.0 + (maxWidth - 300) / 100).clamp(8.0, 10.0);

        return SizedBox(
          width: maxWidth,
          height: 50.0, // 保持高度，与优化后的搜索栏匹配
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: clampedTodayTextWidth,
                child: TodayText(
                  locationStyle: TextStyle(
                    fontSize: locationFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                  dateStyle: TextStyle(
                    fontSize: dateFontSize,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              const SizedBox(width: 105.0), // 保持间距
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), // 与搜索栏一致
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.98),
                        Colors.grey.shade100.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 6),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        EvaIcons.search,
                        color: Colors.grey.shade700,
                        size: 24,
                      ),
                      hintText: "请输入...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 18.0, // 提示文字稍微下移
                        bottom: 14.0,
                      ),
                      isDense: false,
                      alignLabelWithHint: true,
                    ),
                    textAlignVertical: const TextAlignVertical(y: -0.2),
                    onSubmitted: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
