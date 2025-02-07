part of '../manager_screens/manager_dashboard_screen.dart';

class _Header extends StatelessWidget {
  const _Header();

  // 提取魔法数字为局部常量，便于维护
  static const double _headerWidth = 1248.0;
  static const double _todayTextWidth = 300.0;
  static const double _searchFieldWidth = 932.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _headerWidth,
      child: Row(
        children: [
          // 固定宽度的 TodayText
          const SizedBox(
            width: _todayTextWidth,
            child: TodayText(),
          ),
          // 使用全局常量 kSpacing 替代硬编码的间距 16
          const SizedBox(width: kSpacing),
          // 固定宽度的搜索框
          SizedBox(
            width: _searchFieldWidth,
            child: SearchField(),
          ),
        ],
      ),
    );
  }
}
