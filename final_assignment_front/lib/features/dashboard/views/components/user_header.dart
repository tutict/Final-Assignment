part of '../user_screens/user_dashboard.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  // 基础设计稿的固定宽度
  static const double _baseHeaderWidth = 1248.0;
  static const double _baseTodayTextWidth = 300.0;
  static const double _baseSearchFieldWidth = 932.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        // 当分配的宽度小于设计稿宽度时，计算缩放因子；否则使用 1.0
        final double scaleFactor =
            maxWidth < _baseHeaderWidth ? maxWidth / _baseHeaderWidth : 1.0;
        return SizedBox(
          width: maxWidth,
          height: 50.0, // 顶栏高度保持 50 像素
          child: Row(
            children: [
              // TodayText 区域，使用 FittedBox 保证文本适应高度
              SizedBox(
                width: _baseTodayTextWidth * scaleFactor,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TodayText(),
                ),
              ),
              // 使用较小间距
              SizedBox(width: (kSpacing / 2) * scaleFactor),
              // SearchField 区域，外层包裹带边框装饰的 Container
              SizedBox(
                width: _baseSearchFieldWidth * scaleFactor,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // 边框颜色
                    ),
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
