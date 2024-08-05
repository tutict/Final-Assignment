import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

class GetPremiumCard extends StatelessWidget {
  const GetPremiumCard({
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  final Color? backgroundColor;
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
            minWidth: 250,
            maxWidth: 350,
            minHeight: 200,
            maxHeight: 200,
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
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

class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "执法为民\n公正廉洁\n无私奉献",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ).useSystemChineseFont(),
          ),
        ),
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
