part of '../manager_screens/manager_dashboard_screen.dart';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // 假设整个 _Header 可用宽度为 1248 像素，
    // 今天文本占 300 像素，搜索框占 932 像素，中间间距 16 像素
    return SizedBox(
      width: 1248,
      child: Row(
        children: [
          // 固定宽度 300 的 TodayTeconst xt
          const SizedBox(
            width: 300,
            child: TodayText(),
          ),
          // 固定间距 16 像素
          const SizedBox(width: 16),
          // 固定宽度 932 的搜索框
          SizedBox(
            width: 932,
            child: SearchField(),
          ),
        ],
      ),
    );
  }
}
