import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ListProfilImage 小部件用于显示一个可滚动的个人资料图片列表。
///
/// 此小部件接受一组图片、一个可选的回调函数、以及一个最大图片显示数量。
/// 它的主要目的是在有限的空间内有效地显示多张图片，超出最大数量的图片将不会被显示。
class ListProfilImage extends StatelessWidget {
  const ListProfilImage({
    required this.images,
    this.onPressed,
    this.maxImages = 3,
    super.key,
  });

  final List<ImageProvider> images;
  final Function()? onPressed;
  final int maxImages;

  @override
  Widget build(BuildContext context) {
    // 使用 Stack 布局来叠加图片，_getLimitImage 方法用于限制显示的图片数量。
    // 映射并转换图片列表，为每张图片添加间距，并响应 onPressed 回调。
    return Stack(
      alignment: Alignment.centerRight,
      children: _getLimitImage(images, maxImages)
          .asMap()
          .entries
          .map(
            (e) => Padding(
              padding: EdgeInsets.only(right: (e.key * 25.0)),
              child: _image(
                e.value,
                onPressed: onPressed,
              ),
            ),
          )
          .toList(),
    );
  }

  /// _getLimitImage 方法用于限制返回的图片列表长度，以避免超过最大显示数量。
  ///
  /// 如果原始图片数量不超过最大值，返回原始列表；否则，返回一个只包含最大数量图片的子列表。
  List<ImageProvider> _getLimitImage(List<ImageProvider> images, int limit) {
    if (images.length <= limit) {
      return images;
    } else {
      List<ImageProvider> result = [];
      for (int i = 0; i < limit; i++) {
        result.add(images[i]);
      }
      return result;
    }
  }

  /// _image 方法用于构建单个图片 widget。
  ///
  /// 它接受一个图片提供者对象，并可选地接受一个回调函数，当图片被点击时触发该回调。
  Widget _image(ImageProvider image, {Function()? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(Get.context!).cardColor,
        ),
        child: CircleAvatar(
          backgroundImage: image,
          radius: 15,
        ),
      ),
    );
  }
}
