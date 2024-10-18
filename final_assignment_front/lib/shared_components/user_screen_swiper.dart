import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';

/// 用户屏幕上的轮播图组件
///
/// 该组件展示一个可以滑动切换的图片轮播图，并在用户点击图片时触发回调函数
class UserScreenSwiper extends StatelessWidget {
  /// 构造函数
  ///
  /// @param onPressed 当用户点击轮播图中的图片时回调的函数
  const UserScreenSwiper({
    required this.onPressed,
    super.key,
  });

  final Function() onPressed; // 当用户点击图片时触发的回调函数

  @override
  Widget build(BuildContext context) {
    // 图片URL列表，用于轮播图展示
    final List<String> imageUrls = [
      "https://via.placeholder.com/350x150/FF0000/FFFFFF?text=Image+1",
      "https://via.placeholder.com/350x150/00FF00/FFFFFF?text=Image+2",
      "https://via.placeholder.com/350x150/0000FF/FFFFFF?text=Image+3",
    ];

    // 返回一个 Scaffold，其中包含一个 Swiper，用于展示轮播图
    return Scaffold(
      body: Swiper(
        // 构建每个轮播图项的函数
        itemBuilder: (BuildContext context, int index) {
          return Image.network(
            imageUrls[index],
            fit: BoxFit.fill,
          );
        },
        // 轮播图项的数量，基于图片URL列表的长度
        itemCount: imageUrls.length,
        // 轮播图的分页配置
        pagination: const SwiperPagination(),
        // 轮播图的控制配置，如前进后退按钮
        control: const SwiperControl(),
      ),
    );
  }
}
