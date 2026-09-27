import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_chrome.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _cacheSize = -1.0;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.focusAppearance.value) return;
      controller.focusAppearance.value = false;
      _showThemeDialog();
    });
  }

  Future<void> _calculateCacheSize() async {
    try {
      if (mounted) {
        setState(() {
          _cacheSize = 0;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to calculate cache size: $e');
    }
  }

  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    await _calculateCacheSize();
    _showSuccessDialog('缓存已清除');
  }


  void _showSuccessDialog(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: theme,
          child: AlertDialog(
            title: const Text('操作成功'),
            content: Text('$message\n'
                '深色模式: ${controller.currentTheme.value == "Dark" ? "已启用" : "已禁用"}\n'
                '当前主题: ${controller.selectedStyle.value} ${controller.currentTheme.value}\n'
                '缓存大小: ${_cacheSize.toStringAsFixed(2)} MB'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.exitSidebarContent();
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveSettings() {
    _showSuccessDialog('设置已保存');
  }

  void _showThemeDialog() {
    final theme = controller.currentBodyTheme.value;
    final entries = <_ThemeOption>[
      _ThemeOption('Material Light', 'Material', 'Light'),
      _ThemeOption('Material Dark', 'Material', 'Dark'),
      _ThemeOption('Ionic Light', 'Ionic', 'Light'),
      _ThemeOption('Ionic Dark', 'Ionic', 'Dark'),
      _ThemeOption('Traffic Light', 'Traffic', 'Light'),
      _ThemeOption('Traffic Dark', 'Traffic', 'Dark'),
      _ThemeOption('Basic Light', 'Basic', 'Light'),
      _ThemeOption('Basic Dark', 'Basic', 'Dark'),
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: theme,
          child: AlertDialog(
            title: const Text('选择显示主题'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: entries
                    .map((option) => _ThemeOptionTile(
                          option: option,
                          controller: controller,
                          onTap: () {
                            controller.setSelectedStyle(option.style);
                            if (controller.currentTheme.value !=
                                option.brightness) {
                              controller.toggleBodyTheme();
                            }
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = controller.currentBodyTheme.value;
      final currentStyle =
          '${controller.selectedStyle.value} ${controller.currentTheme.value}';
      return DashboardPageTemplate(
        theme: theme,
        title: '设置管理',
        reading: true,
        pageType: DashboardPageType.user,
        onThemeToggle: controller.toggleBodyTheme,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingTile(
                icon: Icons.palette_outlined,
                title: '选择显示主题',
                subtitle: currentStyle,
                onTap: _showThemeDialog,
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.storage_outlined,
                title: '清除缓存',
                subtitle:
                    '${_cacheSize >= 0 ? _cacheSize.toStringAsFixed(2) : "计算中..."} MB',
                onTap: _clearCache,
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.save_outlined,
                title: '保存设置',
                onTap: _saveSettings,
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.home_outlined,
                title: '返回首页',
                onTap: () => controller.exitSidebarContent(),
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.feedback_outlined,
                title: '反馈',
                onTap: () => controller.navigateToPage(Routes.consultation),
              ),
              
            ],
          ),
        ),
      );
    });
  }
}

class _ThemeOption {
  const _ThemeOption(this.label, this.style, this.brightness);

  final String label;
  final String style;
  final String brightness;
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.option,
    required this.controller,
    required this.onTap,
  });

  final _ThemeOption option;
  final UserDashboardController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected =
        controller.selectedStyle.value == option.style &&
        controller.currentTheme.value == option.brightness;

    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        option.label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: selected ? scheme.primary : scheme.onSurface,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.primary;

    return DashboardPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
