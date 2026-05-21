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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    const slides = _UserSafetySlide.slides;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 620;
        final viewportFraction = isCompact ? 0.92 : 0.68;
        final scale = isCompact ? 0.94 : 0.86;
        final swiperHeight =
            (width * viewportFraction / (isCompact ? 1.5 : 1.85))
                .clamp(220.0, 360.0)
                .toDouble();

        return Container(
          height: swiperHeight + 34,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  scheme.outlineVariant.withValues(alpha: dark ? 0.22 : 0.34),
            ),
            color: scheme.surface.withValues(alpha: dark ? 0.12 : 0.20),
          ),
          child: Swiper(
            itemBuilder: (context, index) {
              final slide = slides[index];
              return _SafetySlideCard(
                slide: slide,
                onPressed: onPressed,
              );
            },
            itemCount: slides.length,
            autoplay: true,
            autoplayDelay: 4200,
            duration: 650,
            viewportFraction: viewportFraction,
            scale: scale,
            fade: 0.28,
            pagination: SwiperPagination(
              margin: const EdgeInsets.only(bottom: 5),
              builder: RectSwiperPaginationBuilder(
                activeColor: scheme.primary,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.34),
                size: const Size(18, 3),
                activeSize: const Size(34, 3),
              ),
            ),
            control: SwiperControl(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.86),
              disableColor:
                  scheme.onSurfaceVariant.withValues(alpha: dark ? 0.22 : 0.28),
              size: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        );
      },
    );
  }
}

class _SafetySlideCard extends StatelessWidget {
  const _SafetySlideCard({
    required this.slide,
    required this.onPressed,
  });

  final _UserSafetySlide slide;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.10 : 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.34 : 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    slide.imagePath,
                    fit: BoxFit.cover,
                    alignment: slide.alignment,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0, 0.48, 1],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.54),
                          Colors.black.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.46, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: slide.accent.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slide.tag,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slide.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.34),
                                  offset: const Offset(0, 1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            slide.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.35,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.26),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserSafetySlide {
  const _UserSafetySlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accent,
    this.alignment = Alignment.center,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final String tag;
  final Color accent;
  final Alignment alignment;

  static const slides = [
    _UserSafetySlide(
      imagePath: ImageRasterPath.liangnv1,
      title: '安全驾驶，文明出行',
      subtitle: '出发前确认状态，行驶中保持车距和注意力。',
      tag: '安全提醒',
      accent: Color(0xFF2F80ED),
      alignment: Alignment.center,
    ),
    _UserSafetySlide(
      imagePath: ImageRasterPath.liangnv2,
      title: '遵守交规，平安回家',
      subtitle: '红灯停、礼让行人，减少每一次不必要的风险。',
      tag: '文明通行',
      accent: Color(0xFF25A7A0),
      alignment: Alignment.centerRight,
    ),
    _UserSafetySlide(
      imagePath: ImageRasterPath.liangnv3,
      title: '减速慢行，生命至上',
      subtitle: '夜间、雨雪和拥堵路段主动降速，预留反应空间。',
      tag: '风险预警',
      accent: Color(0xFFE5A33A),
      alignment: Alignment.center,
    ),
  ];
}
