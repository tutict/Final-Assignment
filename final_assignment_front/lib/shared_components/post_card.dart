import 'package:final_assignment_front/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.mutedForegroundColor,
    this.accentColor,
    this.borderColor,
    super.key,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? mutedForegroundColor;
  final Color? accentColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = backgroundColor ?? scheme.surfaceContainerHighest;
    final brightness = ThemeData.estimateBrightnessForColor(background);
    final darkSurface = brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? scheme.primary;
    final effectiveForeground = foregroundColor ??
        (darkSurface ? Colors.white : const Color(0xFF111827));
    final effectiveMutedForeground =
        mutedForegroundColor ?? effectiveForeground.withValues(alpha: 0.72);
    final effectiveBorder = borderColor ??
        effectiveAccent.withValues(alpha: darkSurface ? 0.32 : 0.20);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        splashColor: effectiveAccent.withValues(alpha: 0.10),
        highlightColor: effectiveAccent.withValues(alpha: 0.06),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 180,
            maxWidth: 300,
            minHeight: 168,
            maxHeight: 220,
          ),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: effectiveBorder),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: darkSurface ? 0.14 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -10,
                child: SvgPicture.asset(
                  ImageVectorPath.happy,
                  width: 92,
                  height: 92,
                  colorFilter: ColorFilter.mode(
                    effectiveAccent.withValues(
                        alpha: darkSurface ? 0.18 : 0.14),
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(
                      alpha: darkSurface ? 0.18 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: effectiveAccent,
                    size: 19,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '交通安全\n时时不忘',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: effectiveForeground,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: effectiveAccent.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '幸福生活天天拥有',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: effectiveMutedForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.36,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
