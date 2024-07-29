part of '../screens/user_dashboard_screen.dart';


class UserSidebar extends StatelessWidget {
  const UserSidebar({super.key,
    required this.data,
  });

  final ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
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
                  label: "��ҳ",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.trendingUp,
                  icon: EvaIcons.trendingUpOutline,
                  label: "�������",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.globe,
                  icon: EvaIcons.globeOutline,
                  label: "�������",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.pin,
                  icon: EvaIcons.pinOutline,
                  label: "��������",
                  totalNotif: 20,
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.person,
                  icon: EvaIcons.personOutline,
                  label: "������Ϣ",
                ),
                SelectionButtonData(
                  activeIcon: EvaIcons.settings,
                  icon: EvaIcons.settingsOutline,
                  label: "����",
                ),
              ],
              onSelected: (index, value) {
                log("index : $index | label : ${value.label}");
              },
            ),
            const Divider(thickness: 1),
            const SizedBox(height: kSpacing * 2),
            UpgradePremiumCard(
              backgroundColor: Theme.of(context).canvasColor.withOpacity(.4),
              onPressed: () {},
            ),
            const SizedBox(height: kSpacing),
          ],
        ),
      ),
    );
  }
}
