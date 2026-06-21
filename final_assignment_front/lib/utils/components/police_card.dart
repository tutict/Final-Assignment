import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PoliceCard extends StatelessWidget {
  const PoliceCard({
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  static const String _title =
      '\u6267\u6cd5\u4e3a\u6c11\n\u516c\u6b63\u5ec9\u6d01';
  static const String _subtitle =
      '\u52a0\u5f3a\u7efc\u5408\u6cbb\u7406\uff0c\u4fdd\u969c\u4ea4\u901a\u5b89\u5168';

  final Color? backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final resolvedBackground =
        backgroundColor != null && backgroundColor != Colors.transparent
            ? backgroundColor
            : null;
    final surface = resolvedBackground ??
        Color.lerp(
          scheme.surface,
          scheme.primaryContainer,
          dark ? 0.16 : 0.26,
        )!;
    final borderColor =
        scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.44);
    final accent = scheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        splashColor: accent.withValues(alpha: 0.10),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 180,
            maxWidth: 300,
            minHeight: 150,
            maxHeight: 174,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.12 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -18,
                  child: SvgPicture.asset(
                    ImageVectorPath.police,
                    width: 112,
                    height: 112,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      accent.withValues(alpha: dark ? 0.14 : 0.12),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: dark ? 0.18 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: accent,
                            size: 19,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.20,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
