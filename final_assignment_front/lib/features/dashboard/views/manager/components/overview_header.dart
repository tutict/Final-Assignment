part of '../manager_dashboard_screen.dart';

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
    final selectedCase = Get.find<DashboardController>().selectedCaseType;
    return Obx(() {
      if (widget.axis == Axis.horizontal) {
        // 为了在水平滚动中避免 Expanded 导致无限宽度的问题，
        // 将 Row 的 mainAxisSize 设置为 min，并用 Flexible 替换 Expanded，
        // 同时在外层用 Container 或 SizedBox 设置一个明确宽度（例如通过媒体查询或父级约束）
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 固定宽度的文本区域
            Container(
              // 可以根据设计需求设置一个固定宽度或自动包裹
              constraints: const BoxConstraints(minWidth: 80),
              child: Text(
                "当前工作",
                style: const TextStyle(fontWeight: FontWeight.w600)
                    ,
              ),
            ),
            const SizedBox(width: 8),
            // Flexible 包裹的 SingleChildScrollView 确保内容横向滚动
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildButtons(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "当前工作",
              style: const TextStyle(fontWeight: FontWeight.w600)
                  ,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildButtons(
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

  List<Widget> _buildButtons({
    required CaseType selectedCase,
    required Function(CaseType) onSelected,
  }) {
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
