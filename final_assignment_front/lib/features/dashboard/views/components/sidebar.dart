part of '../screens/manager_dashboard_screen.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.data,
  });

  final ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(kSpacing),
                    child: ProjectCard(
                      data: data,
                    ),
                  ),
                  const Divider(thickness: 1),
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
                      log("index : \$index | label : \${value.label}");
                    },
                  ),
                  const Divider(thickness: 1),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(kSpacing),
            child: PostCard(
              backgroundColor: Theme.of(context).canvasColor.withOpacity(.4),
              onPressed: () {},
            ),
          ),
          const SizedBox(height: kSpacing),
        ],
      ),
    );
  }
}
