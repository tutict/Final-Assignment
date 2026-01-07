import 'package:card_swiper/card_swiper.dart';
import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// 用户屏幕上的轮播图组件
class UserScreenSwiper extends StatelessWidget {
  const UserScreenSwiper({
    required this.onPressed,
    super.key,
  });

  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // 根据页面宽度动态调整 viewportFraction 和 scale
    double viewportFraction;
    double scale;
    if (screenWidth < 600) {
      viewportFraction = 0.85; // 小屏幕，稍宽松
      scale = 0.9;
    } else if (screenWidth < 1000) {
      viewportFraction = 0.75; // 中屏幕，显示部分相邻卡片
      scale = 0.85;
    } else {
      viewportFraction = 0.6; // 大屏幕，显示更多卡片
      scale = 0.75;
    }

    // 动态计算高度，小屏使用 3:2，中大屏使用 16:9
    double aspectRatio = screenWidth < 600 ? 3 / 2 : 16 / 9;
    double swiperHeight = screenWidth * viewportFraction / aspectRatio;
    // 限制高度范围，避免过高或过低
    swiperHeight = swiperHeight.clamp(150.0, screenHeight * 0.45);

    // 图片路径列表
    final List<String> imageUrls = [
      ImageRasterPath.liangnv1,
      ImageRasterPath.liangnv2,
      ImageRasterPath.liangnv3,
    ];

    // 交通安全警示标语列表，与图片一一对应
    final List<String> safetySlogans = [
      '安全驾驶，文明出行',
      '遵守交规，平安回家',
      '减速慢行，生命至上',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      child: SizedBox(
        height: swiperHeight,
        child: Swiper(
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 图片
                      Image.asset(
                        imageUrls[index],
                        fit: BoxFit.cover,
                      ),
                      // 渐变遮罩
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                      // 警示标语
                      Positioned(
                        bottom: 16.0,
                        left: 16.0,
                        right: 16.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            safetySlogans[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          itemCount: imageUrls.length,
          pagination: const SwiperPagination(
            builder: RectSwiperPaginationBuilder(
              activeColor: Colors.blueAccent,
              color: Colors.grey,
              size: Size(10.0, 2.0),
              activeSize: Size(20.0, 2.0),
            ),
          ),
          control: const SwiperControl(
            color: Colors.blueAccent,
            size: 24.0,
          ),
          autoplay: true,
          autoplayDelay: 3000,
          viewportFraction: viewportFraction,
          scale: scale,
          fade: 0.8,
          duration: 500,
        ),
      ),
    );
  }
}
