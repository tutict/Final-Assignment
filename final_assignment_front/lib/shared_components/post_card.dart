import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:final_assignment_front/constants/app_constants.dart';

/// 一个展示帖子的卡片组件
///
/// 该组件可以配置背景颜色和点击事件的回调函数。它通常用于展示一些信息或数据，
/// 并鼓励用户通过点击卡片来获取更多信息。
class PostCard extends StatelessWidget {
  /// 构造函数
  ///
  /// 参数:
  /// - onPressed: 当用户点击卡片时的回调函数
  /// - backgroundColor: 卡片的背景颜色，如果未提供，则使用主题的默认卡片颜色
  const PostCard({
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
      elevation: 6.0,
      shadowColor: Colors.black45,
      child: InkWell(
        borderRadius: BorderRadius.circular(kBorderRadius),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 180,
            maxWidth: 300,
            minHeight: 180,
            maxHeight: 300,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kBorderRadius),
            gradient: LinearGradient(
              colors: [
                Colors.lightBlueAccent.withOpacity(0.4),
                Colors.blue.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                right: 0,
                child: SvgPicture.asset(
                  ImageVectorPath.happy,
                  width: 100,
                  height: 100,
                  color: Colors.blueAccent.withOpacity(0.6),
                  fit: BoxFit.contain,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
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
///
/// 该组件展示了卡片上的标题和描述信息。它通常用于提供关于帖子的一些关键信息，
/// 以吸引用户的注意力。
class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _title(),
        const SizedBox(height: 8),
        _description(),
      ],
    );
  }

  /// 标题文本
  ///
  /// 返回一个展示卡片标题的文本组件。该标题旨在简洁明了地传达帖子的主题或要点。
  Widget _title() {
    return const Text(
      "交通安全时时不忘",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// 描述文本
  ///
  /// 返回一个展示卡片描述的文本组件。该描述提供了关于帖子的一些额外信息或背景，
  /// 以帮助用户更好地理解帖子的内容。
  Widget _description() {
    return const Text(
      "幸福生活天天拥有",
      style: TextStyle(
        fontSize: 16,
        color: Colors.black54,
      ),
    );
  }
}

