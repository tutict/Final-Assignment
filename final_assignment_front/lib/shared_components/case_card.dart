import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';

/// 数据类，用于存储案例卡片的相关信息。
///
/// - `title`: 案例的标题。
/// - `dueDay`: 案例的截止日期，负数表示已逾期。
/// - `profilContributors`: 贡献者的头像列表。
/// - `type`: 案例的类型。
/// - `totalComments`: 案例的评论总数。
/// - `totalContributors`: 案例的贡献者总数。
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
///
/// - `data`: 案例的数据对象。
/// - `onPressedMore`: 点击更多按钮时的回调函数。
/// - `onPressedTask`: 点击任务按钮时的回调函数。
/// - `onPressedContributors`: 点击贡献者按钮时的回调函数。
/// - `onPressedComments`: 点击评论按钮时的回调函数。
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
    return Container(
      constraints: const BoxConstraints(maxWidth: 300), // 设置最大宽度
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius), // 圆角设置
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(5), // 内边距
              child: _Tile(
                title: data.title,
                subtitle: (data.dueDay < 0)
                    ? "Late in ${data.dueDay * -1} days" // 已逾期的情况
                    : "Due in ${(data.dueDay > 1) ? "${data.dueDay} days" : "today"}", // 未逾期的情况
                onPressedMore: onPressedMore,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpacing),
              // 水平内边距
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ListProfilImage(
                    images: data.profilContributors,
                    onPressed: onPressedContributors,
                  ), // 贡献者头像列表
                ],
              ),
            ),
            const SizedBox(height: kSpacing / 2), // 垂直间距
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpacing / 2),
              // 水平内边距
              child: Row(
                children: [
                  _IconButton(
                    iconData: EvaIcons.messageCircleOutline, // 评论图标
                    onPressed: onPressedComments,
                    totalContributors: data.totalComments, // 评论数量
                  ),
                  const SizedBox(width: kSpacing / 2), // 水平间距
                  _IconButton(
                    iconData: EvaIcons.peopleOutline, // 贡献者图标
                    onPressed: onPressedContributors,
                    totalContributors: data.totalContributors, // 贡献者数量
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSpacing / 2), // 垂直间距
          ],
        ),
      ),
    );
  }
}

/* -----------------------------> COMPONENTS <------------------------------ */

/// 标题栏组件，展示案例卡片的标题和更多操作按钮。
///
/// - `title`: 案例的标题。
/// - `subtitle`: 案例的副标题，显示截止日期或逾期情况。
/// - `onPressedMore`: 点击更多按钮时的回调函数。
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16), // 左侧内边距
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 8), // 水平间距
              Expanded(child: _title(title)), // 标题文本
              _moreButton(onPressed: onPressedMore), // 更多按钮
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16), // 水平内边距
          child: _subtitle(subtitle), // 副标题文本
        ),
        const SizedBox(height: 12), // 垂直间距
      ],
    );
  }

  /// 渲染标题文本。
  Widget _title(String data) {
    return Text(
      data,
      textAlign: TextAlign.left,
      maxLines: 1,
      overflow: TextOverflow.ellipsis, // 超出部分省略号显示
    );
  }

  /// 渲染副标题文本。
  Widget _subtitle(String data) {
    return Text(
      data,
      style: Theme.of(Get.context!).textTheme.bodySmall, // 使用主题中的小字体样式
      textAlign: TextAlign.left,
      maxLines: 1,
      overflow: TextOverflow.ellipsis, // 超出部分省略号显示
    );
  }

  /// 渲染更多按钮。
  Widget _moreButton({required Function() onPressed}) {
    return IconButton(
      iconSize: 20, // 图标大小
      onPressed: onPressed,
      icon: const Icon(Icons.more_vert_rounded), // 更多图标
      splashRadius: 20, // 按下时的水波纹半径
    );
  }
}

/// 图标按钮组件，用于执行不同操作。
///
/// - `iconData`: 图标的图标数据。
/// - `totalContributors`: 显示的数字，通常是评论数或贡献者数。
/// - `onPressed`: 点击按钮时的回调函数。
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.iconData,
    required this.totalContributors,
    required this.onPressed,
  });

  final IconData iconData;
  final int totalContributors;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // 背景透明
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius), // 圆角设置
        ),
      ),
      onPressed: onPressed,
      icon: _icon(iconData), // 图标
      label: _label("$totalContributors"), // 数字标签
    );
  }

  /// 渲染数字标签。
  Widget _label(String data) {
    return Text(
      data,
      style: const TextStyle(
        color: Colors.white54, // 文字颜色
        fontSize: 10, // 字体大小
      ).useSystemChineseFont(), // 使用系统中文字体
    );
  }

  /// 渲染图标。
  Widget _icon(IconData iconData) {
    return Icon(
      iconData,
      color: Colors.white54, // 图标颜色
      size: 14, // 图标大小
    );
  }
}
