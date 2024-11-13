import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

/// 参数:
/// - onPressed: 当用户点击卡片时的回调函数。
/// - backgroundColor: 卡片的背景颜色，如果未提供，则使用主题的默认卡片颜色。
class PoliceCard extends StatelessWidget {
  const PoliceCard({
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  final Color? backgroundColor;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    // 返回一个Material组件，用于提供卡片的基本形状和颜色。
    return Material(
      borderRadius: BorderRadius.circular(kBorderRadius),
      color: backgroundColor ?? Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(kBorderRadius),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 250,
            maxWidth: 350,
            minHeight: 200,
            maxHeight: 200,
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              // 在卡片的右上角放置一个SVG图片，用以装饰。
              Positioned(
                top: -15,
                right: -30,
                child: SvgPicture.asset(
                  ImageVectorPath.police,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              // 在卡片的内部放置一个包含卡片信息的Padding组件。
              const Padding(
                padding: EdgeInsets.all(15),
                child: _Info(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 一个内部使用的 StatelessWidget，用于展示卡片的信息。
class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) {
    // 返回一个Column组件，包含卡片的信息文本。
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示卡片的主要信息文本，并使用系统默认的中文字体。
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "执法为民\n公正廉洁\n无私奉献",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ).useSystemChineseFont(),
          ),
        ),
        // 显示卡片的次要信息文本。
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            "加强综合治理，保障交通安全",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
