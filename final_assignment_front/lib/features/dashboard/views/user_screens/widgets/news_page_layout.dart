import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef NewsContentBuilder = Widget Function(
    BuildContext context, ThemeData theme);

class NewsPageLayout extends StatelessWidget {
  const NewsPageLayout({
    super.key,
    required this.title,
    required this.contentBuilder,
    this.accentColor = Colors.blue,
    this.gradient,
    this.leading,
    this.trailing,
  });

  final String title;
  final NewsContentBuilder contentBuilder;
  final Color accentColor;
  final LinearGradient? gradient;
  final Widget? leading;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _darken(accentColor, isDark ? 0.1 : 0.0),
            colorScheme.surface,
          ],
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(gradient: effectiveGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: contentBuilder(context, theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final textColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          leading ??
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          if (trailing != null) ...trailing!,
        ],
      ),
    );
  }

  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}
