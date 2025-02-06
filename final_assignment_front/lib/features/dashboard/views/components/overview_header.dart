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
    // 通过 Get.find 获取 DashboardController 中的 selectedCaseType
    final selectedCase = Get.find<DashboardController>().selectedCaseType;
    return Obx(() {
      if (widget.axis == Axis.horizontal) {
        return Row(
          mainAxisSize: MainAxisSize.min, // 让 Row 根据子内容收缩包装
          children: [
            Text(
              "当前工作",
              style: const TextStyle(fontWeight: FontWeight.w600)
                  .useSystemChineseFont(),
            ),
            const SizedBox(width: 8),
            // 使用 Flexible 替换 Expanded，在水平滚动区域中适应内容尺寸
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // shrink-wrap 子内容
                  children:
                      _buildButtons(selectedCase.value, widget.onSelected),
                ),
              ),
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                mainAxisSize: MainAxisSize.min,
                children: _buildButtons(selectedCase.value, widget.onSelected),
              ),
            ),
          ],
        );
      }
    });
  }

  List<Widget> _buildButtons(
      CaseType selectedCase, Function(CaseType) onSelected) {
    return [
      _buildButton(
        selected: selectedCase == CaseType.caseManagement,
        label: "信息管理",
        onPressed: () => onSelected(CaseType.caseManagement),
      ),
      _buildButton(
        selected: selectedCase == CaseType.caseSearch,
        label: "案件查询",
        onPressed: () => onSelected(CaseType.caseSearch),
      ),
      _buildButton(
        selected: selectedCase == CaseType.caseAppeal,
        label: "案件申诉",
        onPressed: () => onSelected(CaseType.caseAppeal),
      ),
    ];
  }

  Widget _buildButton({
    required bool selected,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor:
              selected ? kFontColorPallets[0] : kFontColorPallets[2],
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
