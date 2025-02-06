part of '../manager_screens/manager_dashboard_screen.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.data,
  });

  final ProjectCardData data; // 自定义数据类型

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme
          .of(context)
          .cardColor,
      // 使用 SingleChildScrollView 包裹整个内容，避免 Expanded 造成无限尺寸问题
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 让子项尽可能填满宽度
          children: [
            Padding(
              padding: const EdgeInsets.all(kSpacing),
              child: ProjectCard(data: data),
            ),
            const Divider(thickness: 1),
            // 使用 SelectionButton 组件（注意：如果 SelectionButton 内部使用了 Expanded，请检查其实现并改为使用 Flexible 或设置 mainAxisSize 为 min）
            SelectionButton(
              data: [
                SelectionButtonData(
                  activeIcon: EvaIcons.grid,
                  icon: EvaIcons.gridOutline,
                  label: "主页",
                  routeName: "homePage",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.map,
                  icon: EvaIcons.archiveOutline,
                  label: "业务点",
                  routeName: "businessPointPage",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.calendar,
                  icon: EvaIcons.calendarOutline,
                  label: "业务办理进度",
                  routeName: "businessProgressPage",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.email,
                  icon: EvaIcons.emailOutline,
                  label: "消息",
                  totalNotif: 20,
                  routeName: "messagePage",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.person,
                  icon: EvaIcons.personOutline,
                  label: "个人信息",
                  routeName: "personalPage",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.settings,
                  icon: EvaIcons.settingsOutline,
                  label: "设置",
                  routeName: "settingsPage",
                ),
              ],
              onSelected: (index, value) {
                log("index : $index | label : ${value.label}");
              },
            ),
            const Divider(thickness: 1),
            Container(
              padding: const EdgeInsets.all(kSpacing),
              child: PostCard(
                backgroundColor: Theme
                    .of(context)
                    .canvasColor
                    .withAlpha((0.4 * 255).toInt()),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}