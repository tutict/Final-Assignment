// 导入必要的包
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

// 定义进度卡片数据类，包含未完成任务和正在进行的任务数量
class ProgressCardData {
  final int totalUndone;
  final int totalTaskInProress;

  // 构造函数
  const ProgressCardData({
    required this.totalUndone,
    required this.totalTaskInProress,
  });
}

// 定义进度卡片组件，用于展示车辆相关信息和操作按钮
class ProgressCard extends StatelessWidget {
  // 构造函数
  const ProgressCard({
    required this.data,
    required this.onPressedCheck,
    super.key,
  });

  final ProgressCardData data;
  final Function() onPressedCheck;

  @override
  Widget build(BuildContext context) {
    // 返回一个卡片组件，包含车辆图案和相关信息
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
          // 车辆图案，使用SVG格式
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
          // 车辆信息和操作按钮
          Padding(
            padding: const EdgeInsets.only(
              left: kSpacing,
              top: kSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 车辆图标和名称
                Row(
                  children: <Widget>[
                    const Icon(Icons.directions_car, size: 44.0),
                    Text(
                      "机动车",
                      style: const TextStyle(fontWeight: FontWeight.w700)
                          ,
                    ),
                  ],
                ),
                const SizedBox(height: kSpacing),
                // 备案机动车信息的按钮
                ElevatedButton(
                  onPressed: onPressedCheck,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.add, size: 24.0),
                      const SizedBox(width: 8.0),
                      Text("备案机动车信息",
                          style: const TextStyle(fontSize: 16.0)
                              ),
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
