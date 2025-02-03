part of '../manager_screens/manager_dashboard_screen.dart';

class OverviewHeader extends StatefulWidget {
  final Function(CaseType) onSelected;
  final Axis axis;

  const OverviewHeader({
    super.key,
    required this.onSelected,
    required this.axis,
  });

  @override
  State<OverviewHeader> createState() => _OverviewHeaderState();
}

class _OverviewHeaderState extends State<OverviewHeader> {
  @override
  Widget build(BuildContext context) {
    // 通过 Get.find 获取 DashboardController 中的响应式变量
    final selectedCase = Get.find<DashboardController>().selectedCaseType;
    return Obx(() {
      if (widget.axis == Axis.horizontal) {
        return Row(
          children: [
            Text(
              "当前工作",
              style: const TextStyle(fontWeight: FontWeight.w600)
                  .useSystemChineseFont(),
            ),
            const SizedBox(width: 8),
            // 使用 Expanded 包裹 SingleChildScrollView，保证按钮部分占满剩余空间，
            // 并且超出时可横向滚动，避免 RenderFlex 溢出
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _listButton(
                    selectedCase: selectedCase.value,
                    onSelected: (value) {
                      selectedCase.value = value;
                      widget.onSelected(value);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "当前工作",
              style: const TextStyle(fontWeight: FontWeight.w600)
                  .useSystemChineseFont(),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _listButton(
                  selectedCase: selectedCase.value,
                  onSelected: (value) {
                    selectedCase.value = value;
                    widget.onSelected(value);
                  },
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  List<Widget> _listButton({
    required CaseType selectedCase,
    required Function(CaseType) onSelected,
  }) {
    return [
      _button(
        selected: selectedCase == CaseType.caseManagement,
        label: "信息管理",
        onPressed: () => onSelected(CaseType.caseManagement),
      ),
      _button(
        selected: selectedCase == CaseType.caseSearch,
        label: "案件查询",
        onPressed: () => onSelected(CaseType.caseSearch),
      ),
      _button(
        selected: selectedCase == CaseType.caseAppeal,
        label: "案件申诉",
        onPressed: () => onSelected(CaseType.caseAppeal),
      ),
    ];
  }

  Widget _button({
    required bool selected,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // 前景色（文字颜色）根据选中状态变化
          foregroundColor:
              selected ? kFontColorPallets[0] : kFontColorPallets[2],
          // 背景色根据选中状态变化
          backgroundColor: selected
              ? Theme.of(context).cardColor
              : Theme.of(context).canvasColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
