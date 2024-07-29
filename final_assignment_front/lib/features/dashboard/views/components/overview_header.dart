part of '../screens/manager_dashboard_screen.dart';

class _OverviewHeader extends StatefulWidget {
  const _OverviewHeader({
    required this.onSelected, required this.axis,
  });

  final Function(CaseType) onSelected;  // Ensure onSelected expects a CaseType
  final Axis axis;

  @override
  State<_OverviewHeader> createState() => _OverviewHeaderState();
}

class _OverviewHeaderState extends State<_OverviewHeader> {
  @override
  Widget build(BuildContext context) {
    // 使用Get.find来访问DashboardController中的响应式变量
    final selectedCase = Get.find<DashboardController>().selectedCaseType;
    return Obx(
          () => (widget.axis == Axis.horizontal)
          ? Row(
        children: [
          const Text(
            "当前工作",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          ..._listButton(
            selectedCase: selectedCase.value,
            onSelected: (value) {
              selectedCase.value = value;
              widget.onSelected(value);
            },
          )
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "当前工作",
            style: TextStyle(fontWeight: FontWeight.w600),
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
      ),
    );
  }

  List<Widget> _listButton({
    required CaseType selectedCase,  // 确保selectedCase是CaseType类型
    required Function(CaseType) onSelected,
  }) {
    return [
      _button(
        selected: selectedCase == CaseType.caseManagement,
        label: "信息管理",
        onPressed: () => onSelected(CaseType.caseManagement), // 修改这里，移除错误的参数并正确传递枚举值
      ),
      _button(
        selected: selectedCase == CaseType.caseSearch,
        label: "案件查询",
        onPressed: () => onSelected(CaseType.caseSearch), // 修改这里，同上
      ),
      _button(
        selected: selectedCase == CaseType.caseAppeal,
        label: "案件申诉",
        onPressed: () => onSelected(CaseType.caseAppeal), // 修改这里，同上
      ),
    ];
  }

  Widget _button({
    required bool selected,
    required String label,
    required VoidCallback onPressed, // 修改这里，使用VoidCallback代替Function(CaseType)
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: selected ? kFontColorPallets[0] : kFontColorPallets[2],
          backgroundColor: selected
              ? Theme.of(Get.context!).cardColor
              : Theme.of(Get.context!).canvasColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ), // 使用onPressed回调
        child: Text(
          label,
        ),
      ),
    );
  }
}
