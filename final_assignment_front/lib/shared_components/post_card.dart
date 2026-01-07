import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

/// 一个展示帖子的卡片组件
class PostCard extends StatelessWidget {
  const PostCard({
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  final Color? backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(kBorderRadius + 4),
      // 稍微增大圆角
      color: backgroundColor ?? Theme.of(context).cardColor,
      elevation: 4.0,
      // 降低阴影高度，更柔和
      shadowColor: Colors.black.withValues(alpha: 0.2),
      // 阴影颜色更自然
      child: InkWell(
        borderRadius: BorderRadius.circular(kBorderRadius + 4),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 180,
            maxWidth: 300,
            minHeight: 180,
            maxHeight: 300,
          ),
          padding: const EdgeInsets.all(20), // 增加内边距
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kBorderRadius + 4),
            gradient: LinearGradient(
              colors: [
                Colors.lightBlueAccent.withValues(alpha: 0.2), // 渐变更柔和
                Colors.blue.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.1), // 添加微边框
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // SVG 背景图标
              Positioned(
                bottom: 8,
                right: 8,
                child: SvgPicture.asset(
                  ImageVectorPath.happy,
                  width: 80, // 缩小图标尺寸
                  height: 80,
                  colorFilter: ColorFilter.mode(
                    Colors.blueAccent.withValues(alpha: 0.3), // 更淡的颜色
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              // 信息区域
              const Padding(
                padding: EdgeInsets.all(8),
                child: _Info(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片上的信息部分
class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _title(context),
        const SizedBox(height: 12), // 增加间距
        _description(context),
      ],
    );
  }

  /// 标题文本
  Widget _title(BuildContext context) {
    return Text(
      "交通安全时时不忘",
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 22, // 稍微增大标题
            fontWeight: FontWeight.w600, // 加粗
            color: Colors.black87,
            letterSpacing: 0.5, // 微调字符间距
          ),
    );
  }

  /// 描述文本
  Widget _description(BuildContext context) {
    return Text(
      "幸福生活天天拥有",
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 16,
            color: Colors.black.withValues(alpha: 0.7), // 稍微加深颜色
            height: 1.5, // 增加行高
          ),
    );
  }
}
