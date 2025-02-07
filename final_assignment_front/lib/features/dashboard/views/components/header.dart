part of '../manager_screens/manager_dashboard_screen.dart';

class _Header extends StatelessWidget {
  const _Header();

  // 基础设计稿中的固定宽度
  static const double _baseHeaderWidth = 1248.0;
  static const double _baseTodayTextWidth = 300.0;
  static const double _baseSearchFieldWidth = 932.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        // 当分配的宽度小于设计稿宽度时，计算缩放因子
        final double scaleFactor =
            maxWidth < _baseHeaderWidth ? maxWidth / _baseHeaderWidth : 1.0;
        return SizedBox(
          width: maxWidth,
          height: 50.0, // 顶栏高度保持 50
          child: Row(
            children: [
              // TodayText 区域
              SizedBox(
                width: _baseTodayTextWidth * scaleFactor,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TodayText(),
                ),
              ),
              // 较小的间距
              SizedBox(width: (kSpacing / 2) * scaleFactor),
              // SearchField 区域
              SizedBox(
                width: _baseSearchFieldWidth * scaleFactor,
                child: SearchField(),
              ),
            ],
          ),
        );
      },
    );
  }
}
