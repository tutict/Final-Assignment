import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_app_bar.dart';

class UserPageBarAction extends DashboardPageBarAction {
  const UserPageBarAction({
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.color,
  });
}

class UserPageAppBar extends DashboardPageAppBar {
  const UserPageAppBar({
    super.key,
    required super.theme,
    required super.title,
    super.leading,
    List<UserPageBarAction> actions = const [],
    super.onRefresh,
    super.onThemeToggle,
    super.automaticallyImplyLeading = true,
  }) : super(actions: actions);
}
