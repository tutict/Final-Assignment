part of '../manager_screens/manager_dashboard_screen.dart';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // TodayText 宽度占屏幕宽度的 25%，收缩 1.5cm（38 像素）
        final double todayTextWidth = maxWidth * 0.25;
        final double clampedTodayTextWidth =
            (todayTextWidth - 38.0).clamp(80.0, 262.0);

        // 动态调整字体大小，确保总高度不超过 38（50 - 12 padding）
        final double locationFontSize =
            (10.0 + (maxWidth - 300) / 100).clamp(10.0, 14.0);
        final double dateFontSize =
            (8.0 + (maxWidth - 300) / 100).clamp(8.0, 10.0);

        return SizedBox(
          width: maxWidth,
          height: 50.0, // 保持顶栏高度为 50 像素
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
              const SizedBox(width: 16.0), // 固定间距，与 UserHeader 一致
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SearchField(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
