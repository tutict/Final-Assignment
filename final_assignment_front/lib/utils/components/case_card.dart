import 'package:final_assignment_front/shared/eva_icons_compat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/utils/components/list_profil_image.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';

/// 数据类，用于存储案例卡片的相关信息。
class CaseCardData {
  final String title;
  final int dueDay;
  final List<ImageProvider> profilContributors;
  final CaseType type;
  final int totalComments;
  final int totalContributors;

  const CaseCardData({
    required this.title,
    required this.dueDay,
    required this.totalComments,
    required this.totalContributors,
    required this.type,
    required this.profilContributors,
  });
}

/// 案例卡片组件，展示案例相关信息。
class CaseCard extends StatelessWidget {
  const CaseCard({
    required this.data,
    required this.onPressedMore,
    required this.onPressedTask,
    required this.onPressedContributors,
    required this.onPressedComments,
    super.key,
  });

  final CaseCardData data;
  final Function() onPressedMore;
  final Function() onPressedTask;
  final Function() onPressedContributors;
  final Function() onPressedComments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 150),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.45 : 0.58),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: dark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: _Tile(
              title: data.title,
              subtitle: (data.dueDay < 0)
                  ? "Late in ${data.dueDay * -1} days"
                  : "Due in ${(data.dueDay > 1) ? "${data.dueDay} days" : "today"}",
              onPressedMore: onPressedMore,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacing),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ListProfilImage(
                  images: data.profilContributors,
                  onPressed: onPressedContributors,
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacing / 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacing / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CaseActionIconButton(
                  iconData: EvaIcons.messageCircleOutline,
                  onPressed: onPressedComments,
                  totalContributors: data.totalComments,
                ),
                const SizedBox(width: kSpacing / 2),
                _CaseActionIconButton(
                  iconData: EvaIcons.peopleOutline,
                  onPressed: onPressedContributors,
                  totalContributors: data.totalContributors,
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacing / 2),
        ],
      ),
    );
  }
}

/* -----------------------------> COMPONENTS <------------------------------ */

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.onPressedMore,
  });

  final String title;
  final String subtitle;
  final Function() onPressedMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              _title(title),
              _moreButton(onPressed: onPressedMore),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _subtitle(subtitle),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _title(String data) {
    return Text(
      data,
      textAlign: TextAlign.left,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(Get.context!).textTheme.titleMedium,
    );
  }

  Widget _subtitle(String data) {
    return Text(
      data,
      style: Theme.of(Get.context!).textTheme.bodySmall,
      textAlign: TextAlign.left,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _moreButton({required Function() onPressed}) {
    return IconButton(
      iconSize: 20,
      onPressed: onPressed,
      icon: const Icon(Icons.more_vert_rounded),
      splashRadius: 20,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      ),
    );
  }
}

class _CaseActionIconButton extends StatelessWidget {
  const _CaseActionIconButton({
    required this.iconData,
    required this.totalContributors,
    required this.onPressed,
  });

  final IconData iconData;
  final int totalContributors;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      onPressed: onPressed,
      icon: Icon(
        iconData,
        color: scheme.onSurfaceVariant,
        size: 14,
      ),
      label: Text(
        "$totalContributors",
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }
}
