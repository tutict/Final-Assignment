import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

class ProgressCardData {
  final int totalUndone;
  final int totalTaskInProress;

  const ProgressCardData({
    required this.totalUndone,
    required this.totalTaskInProress,
  });
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    required this.data,
    required this.onPressedCheck,
    super.key,
  });

  final ProgressCardData data;
  final Function() onPressedCheck;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        side: const BorderSide(
          color: Colors.white,
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(kBorderRadius),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                offset: const Offset(10, 30),
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: SvgPicture.asset(
                    ImageVectorPath.car,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: kSpacing,
              top: kSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.directions_car, size: 44.0),
                    Text(
                      "机动车",
                      style: const TextStyle(fontWeight: FontWeight.w700).useSystemChineseFont(),
                    ),
                  ],
                ),
                const SizedBox(height: kSpacing),
                ElevatedButton(
                  onPressed: onPressedCheck,
                  child:Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                          const Icon(Icons.add, size: 24.0),
                          const SizedBox(width: 8.0),
                          Text("备案机动车信息", style: const TextStyle(fontSize: 16.0).useSystemChineseFont()),
                      ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
