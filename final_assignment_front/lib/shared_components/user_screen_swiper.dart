import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';

class UserScreenSwiper extends StatelessWidget {
  const UserScreenSwiper({
    required this.onPressed,
    super.key,
  });

  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    // 图片的URL列表
    final List<String> imageUrls = [
      "https://via.placeholder.com/350x150/FF0000/FFFFFF?text=Image+1",
      "https://via.placeholder.com/350x150/00FF00/FFFFFF?text=Image+2",
      "https://via.placeholder.com/350x150/0000FF/FFFFFF?text=Image+3",
    ];

    return Scaffold(
      body: Swiper(
        itemBuilder: (BuildContext context, int index) {
          return Image.network(
            imageUrls[index],
            fit: BoxFit.fill,
          );
        },
        itemCount: imageUrls.length,  // 使用图片数量作为itemCount
        pagination: const SwiperPagination(),
        control: const SwiperControl(),
      ),
    );
  }
}
