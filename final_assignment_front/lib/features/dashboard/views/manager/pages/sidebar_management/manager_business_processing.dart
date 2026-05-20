import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/deduction_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/driver_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/fine_list_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/manager_appeal_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/offense_list.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/vehicle_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagerBusinessProcessing extends StatefulWidget {
  const ManagerBusinessProcessing({super.key});

  @override
  State<ManagerBusinessProcessing> createState() =>
      _ManagerBusinessProcessingState();
}

class _ManagerBusinessProcessingState extends State<ManagerBusinessProcessing> {
  late ManagerDashboardController controller;

  final List<_BusinessOption> businessOptions = const [
    _BusinessOption(
      title: '申诉管理',
      description: '复核驾驶员申诉材料、处理意见和办理进度',
      metric: '7 项待核',
      icon: Icons.gavel_rounded,
      route: ManagerAppealManagementPage(),
    ),
    _BusinessOption(
      title: '扣分管理',
      description: '核对违法扣分记录，维护驾驶证计分状态',
      metric: '规则校验',
      icon: Icons.fact_check_rounded,
      route: DeductionManagementPage(),
    ),
    _BusinessOption(
      title: '司机管理',
      description: '查看驾驶员档案、证件信息与账号关联状态',
      metric: '身份档案',
      icon: Icons.badge_rounded,
      route: DriverListPage(),
    ),
    _BusinessOption(
      title: '罚款管理',
      description: '跟进罚款开具、缴纳状态和异常款项处理',
      metric: '支付跟进',
      icon: Icons.receipt_long_rounded,
      route: FineListPage(),
    ),
    _BusinessOption(
      title: '车辆管理',
      description: '维护车辆信息、绑定关系与违法关联记录',
      metric: '车辆台账',
      icon: Icons.directions_car_filled_rounded,
      route: VehicleList(),
    ),
    _BusinessOption(
      title: '违法行为',
      description: '检索违法行为明细，快速定位待处理案件',
      metric: '数据核验',
      icon: Icons.report_problem_rounded,
      route: OffenseList(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    DashboardBinding.registerDependencies();
    controller = Get.find<ManagerDashboardController>();
  }

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
              final scheme = Theme.of(context).colorScheme;

              return Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BusinessProcessingHeader(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 1120
                                ? 3
                                : width >= 560
                                    ? 2
                                    : 1;
                            final aspectRatio = crossAxisCount == 1
                                ? 4.2
                                : crossAxisCount == 2
                                    ? 2.35
                                    : 3.05;

                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: businessOptions.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: aspectRatio,
                              ),
                              itemBuilder: (context, index) {
                                final option = businessOptions[index];
                                return _BusinessOptionTile(
                                  option: option,
                                  accentColor:
                                      _accentColor(scheme, index, themeData),
                                  onTap: () => _navigateToBusiness(
                                    option.route,
                                  ),
                                );
                              },
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
      const Color(0xFF7C8CF8),
      const Color(0xFFE65E73),
      const Color(0xFF2F9B6A),
      const Color(0xFFE5A33A),
    ];
    final color = colors[index % colors.length];
    return theme.brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, 0.12)!
        : Color.lerp(color, Colors.black, 0.04)!;
  }
}

class _BusinessProcessingHeader extends StatelessWidget {
  const _BusinessProcessingHeader();

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
              Icons.assignment_turned_in_rounded,
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
                  '业务处理',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '集中处理申诉、扣分、司机、罚款、车辆和违法行为数据。',
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
              '6 个入口',
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

class _BusinessOptionTile extends StatefulWidget {
  const _BusinessOptionTile({
    required this.option,
    required this.accentColor,
    required this.onTap,
  });

  final _BusinessOption option;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_BusinessOptionTile> createState() => _BusinessOptionTileState();
}

class _BusinessOptionTileState extends State<_BusinessOptionTile> {
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
                            widget.option.metric,
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

class _BusinessOption {
  const _BusinessOption({
    required this.title,
    required this.description,
    required this.metric,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final String metric;
  final IconData icon;
  final Widget route;
}
