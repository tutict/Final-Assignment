import 'package:final_assignment_front/features/dashboard/bindings/manager_dashboard_binding.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/login_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/operation_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/logs/system_log_page.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/sidebar_management/rag_management_page.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SystemGovernancePage extends StatefulWidget {
  const SystemGovernancePage({super.key});

  @override
  State<SystemGovernancePage> createState() => _SystemGovernancePageState();
}

class _SystemGovernancePageState extends State<SystemGovernancePage> {
  late ManagerDashboardController controller;

  final List<_GovernanceOption> options = const [
    _GovernanceOption(
      title: '操作日志审查',
      description: '审查关键业务操作、异常请求和幂等链路。',
      metric: 'Audit',
      icon: Icons.manage_search_rounded,
      route: OperationLogPage(),
    ),
    _GovernanceOption(
      title: '登录日志审查',
      description: '核对登录来源、失败记录、浏览器和设备信息。',
      metric: 'Login',
      icon: Icons.login_rounded,
      route: LoginLogPage(),
    ),
    _GovernanceOption(
      title: '系统请求日志',
      description: '查看接口请求历史、业务状态和异常回放线索。',
      metric: 'System',
      icon: Icons.route_rounded,
      route: SystemLogPage(),
    ),
    _GovernanceOption(
      title: 'RAG 资料管理',
      description: '录入知识资料、触发回填并检查索引切片状态。',
      metric: 'RAG',
      icon: Icons.library_books_rounded,
      route: RagManagementPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    DashboardBinding.registerDependencies();
    controller = Get.find<ManagerDashboardController>();
  }

  void _open(Widget route) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => route));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: '系统治理',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(themeData: themeData),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1080
                        ? 4
                        : width >= 760
                            ? 2
                            : 1;
                    return GridView.builder(
                      itemCount: options.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: crossAxisCount == 1 ? 3.7 : 2.35,
                      ),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return _GovernanceTile(
                          option: option,
                          onTap: () => _open(option.route),
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
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.themeData});

  final ThemeData themeData;

  @override
  Widget build(BuildContext context) {
    final scheme = themeData.colorScheme;
    final dark = themeData.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: scheme.primaryContainer.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.security_rounded,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '超级管理员工作区',
                  style: themeData.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '集中审查系统日志、异常链路和 RAG 知识资料，普通管理员仅处理业务。',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: themeData.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GovernanceTile extends StatefulWidget {
  const _GovernanceTile({
    required this.option,
    required this.onTap,
  });

  final _GovernanceOption option;
  final VoidCallback onTap;

  @override
  State<_GovernanceTile> createState() => _GovernanceTileState();
}

class _GovernanceTileState extends State<_GovernanceTile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.lerp(
                scheme.surface,
                scheme.primary,
                hovered ? (dark ? 0.08 : 0.04) : 0,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hovered
                    ? scheme.primary.withValues(alpha: 0.56)
                    : scheme.outlineVariant.withValues(alpha: 0.44),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: dark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.option.icon, color: scheme.primary),
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
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            widget.option.metric,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
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
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GovernanceOption {
  const _GovernanceOption({
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
