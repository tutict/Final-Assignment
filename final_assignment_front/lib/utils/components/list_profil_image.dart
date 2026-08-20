import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ListProfilImage 小部件用于显示一个可滚动的个人资料图片列表。
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
    final scheme = Theme.of(Get.context!).colorScheme;

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
                scheme: scheme,
              ),
            ),
          )
          .toList(),
    );
  }

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

  Widget _image(ImageProvider image, {Function()? onPressed, required ColorScheme scheme}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: scheme.surfaceContainerHighest,
        ),
        child: CircleAvatar(
          backgroundImage: image,
          radius: 15,
        ),
      ),
    );
  }
}
