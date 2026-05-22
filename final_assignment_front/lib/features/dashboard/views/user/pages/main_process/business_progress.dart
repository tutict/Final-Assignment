import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/fine_information.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_appeal.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_offense_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/vehicle_management_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessProgressPage extends StatefulWidget {
  const BusinessProgressPage({super.key});

  @override
  State<BusinessProgressPage> createState() => _BusinessProgressPageState();
}

class _BusinessProgressPageState extends State<BusinessProgressPage> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  final List<_UserBusinessOption> businessOptions = const [
    _UserBusinessOption(
      title: '违法详情',
      description: '查看个人违法记录、处理状态和关联车辆信息。',
      status: '待核验',
      icon: Icons.info_rounded,
      route: UserOffenseListPage(),
    ),
    _UserBusinessOption(
      title: '罚款缴纳',
      description: '核对缴款记录，进入罚款信息与支付状态页面。',
      status: '在线办理',
      icon: Icons.credit_card_rounded,
      route: FineInformationPage(),
    ),
    _UserBusinessOption(
      title: '用户申诉',
      description: '提交申诉材料，跟进审核意见和办理进度。',
      status: '材料提交',
      icon: Icons.gavel_rounded,
      route: UserAppealPage(),
    ),
    _UserBusinessOption(
      title: '车辆登记',
      description: '维护车牌、车主和车辆档案等基础资料。',
      status: '资料维护',
      icon: Icons.directions_car_filled_rounded,
      route: VehicleManagementPage(),
    ),
  ];

  void _navigateToBusiness(Widget route) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final themeData = controller.currentBodyTheme.value;

        return Theme(
          data: themeData,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);

              return Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BusinessProgressHeader(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 520 ? 2 : 1;
                            final double? tileExtent = crossAxisCount == 1
                                ? (width < 340 ? 104 : 98)
                                : null;

                            return Column(
                              children: [
                                Expanded(
                                  child: GridView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: businessOptions.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 2.0,
                                      mainAxisExtent: tileExtent,
                                    ),
                                    itemBuilder: (context, index) {
                                      final option = businessOptions[index];
                                      return _UserBusinessTile(
                                        option: option,
                                        accentColor: _accentColor(
                                          theme.colorScheme,
                                          index,
                                          theme,
                                        ),
                                        onTap: () =>
                                            _navigateToBusiness(option.route),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const _BusinessProgressHint(),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _accentColor(ColorScheme scheme, int index, ThemeData theme) {
    final colors = [
      scheme.primary,
      const Color(0xFF25A7A0),
      const Color(0xFFE5A33A),
      const Color(0xFF7C8CF8),
    ];
    final color = colors[index % colors.length];
    return theme.brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, 0.12)!
        : Color.lerp(color, Colors.black, 0.04)!;
  }
}

class _BusinessProgressHeader extends StatelessWidget {
  const _BusinessProgressHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: dark ? 0.34 : 0.58,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.48),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assignment_rounded,
              color: scheme.onPrimaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '业务办理',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '集中处理违法查询、罚款缴纳、申诉提交和车辆资料维护。',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: dark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '4 个入口',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBusinessTile extends StatefulWidget {
  const _UserBusinessTile({
    required this.option,
    required this.accentColor,
    required this.onTap,
  });

  final _UserBusinessOption option;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_UserBusinessTile> createState() => _UserBusinessTileState();
}

class _UserBusinessTileState extends State<_UserBusinessTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final borderColor = _hovered
        ? widget.accentColor.withValues(alpha: dark ? 0.72 : 0.56)
        : scheme.outlineVariant.withValues(alpha: dark ? 0.36 : 0.48);
    final backgroundColor = _hovered
        ? Color.lerp(
            scheme.surface,
            widget.accentColor,
            dark ? 0.08 : 0.045,
          )!
        : scheme.surface.withValues(alpha: dark ? 0.78 : 0.96);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: widget.accentColor.withValues(alpha: 0.10),
          highlightColor: widget.accentColor.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(
                    alpha: _hovered ? (dark ? 0.24 : 0.10) : 0.04,
                  ),
                  blurRadius: _hovered ? 18 : 10,
                  offset: Offset(0, _hovered ? 10 : 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(
                      alpha: dark ? 0.24 : 0.13,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.option.icon,
                    color: widget.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.option.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.option.status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.accentColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.option.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? widget.accentColor.withValues(alpha: 0.18)
                        : scheme.surfaceContainerHighest.withValues(
                            alpha: dark ? 0.36 : 0.52,
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color:
                        _hovered ? widget.accentColor : scheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessProgressHint extends StatelessWidget {
  const _BusinessProgressHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: dark ? 0.11 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.primary.withValues(alpha: dark ? 0.28 : 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: scheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '办理前请确认身份证号、驾驶证号和车辆资料已完善。',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBusinessOption {
  const _UserBusinessOption({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final String status;
  final IconData icon;
  final Widget route;
}
