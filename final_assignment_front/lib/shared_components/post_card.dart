import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

// 升级会员卡组件，用于鼓励用户升级到高级会员
class UpgradePremiumCard extends StatelessWidget {
  /// 构造函数
  ///
  /// 参数:
  /// - onPressed: 当用户点击卡片时的回调函数
  /// - backgroundColor: 卡片的背景颜色，如果未提供，则使用主题的默认卡片颜色
  const UpgradePremiumCard({
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  // 卡片的背景颜色
  final Color? backgroundColor;

  // 当用户点击卡片时的回调函数
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(kBorderRadius),
      color: backgroundColor ?? Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(kBorderRadius),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 150,
            maxWidth: 250,
            minHeight: 150,
            maxHeight: 250,
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 80,
                ),
                child: SvgPicture.asset(
                  ImageVectorPath.happy,
                  fit: BoxFit.contain,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: _Info(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 卡片上的信息部分
class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(),
        const SizedBox(height: 2),
      ],
    );
  }

  // 标题文本
  Widget _title() {
    return const Text(
      "交通安全时时不忘\n幸福生活天天拥有",
    );
  }
}
