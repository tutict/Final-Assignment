// TODO Implement this library.import 'dart:nativewrappers/_internal/vm/lib/developer.dart';

import 'dart:nativewrappers/_internal/vm/lib/developer.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:flutter/material.dart';

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
                  icon: EvaIcons.globe2Outline,
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
