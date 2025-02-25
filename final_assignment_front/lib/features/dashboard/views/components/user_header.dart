part of '../user_screens/user_dashboard.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // TodayText 宽度占屏幕宽度的 25%
        final double todayTextWidth = maxWidth * 0.25;
        // 收缩 1.5cm（约 38 像素），并限制范围
        final double clampedTodayTextWidth =
            (todayTextWidth - 38.0).clamp(80.0, 262.0);

        // 调整字体大小，确保总高度不超过 34（50 - 16 padding）
        final double locationFontSize =
            (10.0 + (maxWidth - 300) / 100).clamp(10.0, 14.0);
        final double dateFontSize =
            (8.0 + (maxWidth - 300) / 100).clamp(8.0, 10.0);

        return SizedBox(
          width: maxWidth,
          height: 50.0,
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
              const SizedBox(width: 16.0),
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
