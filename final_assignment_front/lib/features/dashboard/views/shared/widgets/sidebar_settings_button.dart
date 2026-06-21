import 'dart:async';

import 'package:final_assignment_front/config/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SidebarSettingsButton extends StatelessWidget {
  const SidebarSettingsButton({
    super.key,
    required this.collapsed,
    required this.selectedStyle,
    required this.themeMode,
    required this.onThemeSelected,
  });

  final bool collapsed;
  final String selectedStyle;
  final String themeMode;
  final FutureOr<void> Function(String style, String mode) onThemeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final foreground = scheme.onSurfaceVariant;
    final background = scheme.surfaceContainerHighest.withValues(
      alpha: dark ? 0.32 : 0.54,
    );
    final border = scheme.outlineVariant.withValues(
      alpha: dark ? 0.42 : 0.56,
    );

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: collapsed ? 44 : 50,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(Icons.settings_outlined, color: foreground, size: 22),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '设置',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: foreground, size: 22),
          ],
        ],
      ),
    );

    return Tooltip(
      message: collapsed ? '设置' : '',
      waitDuration: const Duration(milliseconds: 350),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSettingsSheet(context),
          borderRadius: BorderRadius.circular(8),
          splashColor: scheme.primary.withValues(alpha: 0.10),
          highlightColor: scheme.primary.withValues(alpha: 0.06),
          child: content,
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _SidebarSettingsSheet(
          selectedStyle: selectedStyle,
          themeMode: themeMode,
          onThemeSelected: onThemeSelected,
        );
      },
    );
  }
}

class _SidebarSettingsSheet extends StatefulWidget {
  const _SidebarSettingsSheet({
    required this.selectedStyle,
    required this.themeMode,
    required this.onThemeSelected,
  });

  final String selectedStyle;
  final String themeMode;
  final FutureOr<void> Function(String style, String mode) onThemeSelected;

  @override
  State<_SidebarSettingsSheet> createState() => _SidebarSettingsSheetState();
}

class _SidebarSettingsSheetState extends State<_SidebarSettingsSheet> {
  late String _selectedStyle;
  late String _themeMode;
  bool _clearing = false;

  static final List<_ThemePreset> _presets = [
    _ThemePreset(
      label: 'Basic',
      description: '政务蓝灰',
      lightColor: AppTheme.basicLight.colorScheme.primary,
      darkColor: AppTheme.basicDark.colorScheme.primary,
    ),
    _ThemePreset(
      label: 'Ionic',
      description: '清爽青蓝',
      lightColor: AppTheme.ionicLightTheme.colorScheme.primary,
      darkColor: AppTheme.ionicDarkTheme.colorScheme.primary,
    ),
    _ThemePreset(
      label: 'Material',
      description: '强调洋红',
      lightColor: AppTheme.materialLightTheme.colorScheme.primary,
      darkColor: AppTheme.materialDarkTheme.colorScheme.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.selectedStyle;
    _themeMode = widget.themeMode;
  }

  Future<void> _applyTheme({
    String? style,
    String? mode,
  }) async {
    final nextStyle = style ?? _selectedStyle;
    final nextMode = mode ?? _themeMode;
    setState(() {
      _selectedStyle = nextStyle;
      _themeMode = nextMode;
    });
    await widget.onThemeSelected(nextStyle, nextMode);
  }

  Future<void> _clearCache() async {
    if (_clearing) return;
    setState(() => _clearing = true);
    try {
      await DefaultCacheManager().emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清理')),
      );
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '侧边栏设置',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        '调整界面主题，清理本地图片和网络缓存',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '主题模式',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Light',
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('亮色'),
                  ),
                  ButtonSegment(
                    value: 'Dark',
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('暗色'),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: (values) => _applyTheme(mode: values.first),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '主题风格',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            ..._presets.map(
              (preset) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ThemePresetTile(
                  preset: preset,
                  selected: _selectedStyle == preset.label,
                  darkMode: _themeMode == 'Dark',
                  onTap: () => _applyTheme(style: preset.label),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _CacheActionTile(
              clearing: _clearing,
              onPressed: _clearCache,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.preset,
    required this.selected,
    required this.darkMode,
    required this.onTap,
  });

  final _ThemePreset preset;
  final bool selected;
  final bool darkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = darkMode ? preset.darkColor : preset.lightColor;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.56)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.56)
                  : scheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      preset.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CacheActionTile extends StatelessWidget {
  const _CacheActionTile({
    required this.clearing,
    required this.onPressed,
  });

  final bool clearing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: clearing ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.error.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            children: [
              if (clearing)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: scheme.error,
                  ),
                )
              else
                Icon(
                  Icons.cleaning_services_outlined,
                  color: scheme.error,
                  size: 22,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clearing ? '正在清理缓存' : '清理缓存',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      '清除图片与网络临时文件，不影响登录状态',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreset {
  const _ThemePreset({
    required this.label,
    required this.description,
    required this.lightColor,
    required this.darkColor,
  });

  final String label;
  final String description;
  final Color lightColor;
  final Color darkColor;
}
