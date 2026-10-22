import 'package:final_assignment_front/config/routes/app_routes.dart';

/// 外壳路由参数：路由重定向时携带的 page/guide/section 等信息。
///
/// [requestId] 由重定向方在每次跳转时生成，用来区分"同一份参数"和"新一次跳转"，
/// 这样同一份参数不会被重复消费，而连续两次跳转到相同页面也都能生效。
class ShellArguments {
  const ShellArguments({
    this.requestId,
    this.page,
    this.guide,
    this.openChat = false,
    this.section,
  });

  factory ShellArguments.from(Object? raw) {
    if (raw is! Map) return const ShellArguments();
    String? text(String key) {
      final value = raw[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    return ShellArguments(
      requestId: text('requestId'),
      page: text('page'),
      guide: text('guide'),
      openChat: raw['openChat'] == true,
      section: text('section'),
    );
  }

  final String? requestId;
  final String? page;
  final String? guide;
  final bool openChat;
  final String? section;

  /// 参数指纹：参数内容相同时指纹相同，用于判断是否已经消费过。
  String get signature => <Object?>[
        requestId ?? '',
        page ?? '',
        guide ?? '',
        section ?? '',
        openChat,
      ].join('|');

  /// 有效引导标识：路由参数优先，其次是地址栏查询参数。
  String? effectiveGuide() {
    final fromArgs = guide;
    if (fromArgs != null && fromArgs.isNotEmpty) return fromArgs;
    final fromQuery = Uri.base.queryParameters['guide'];
    if (fromQuery == null || fromQuery.isEmpty) return null;
    return fromQuery;
  }

  /// 有效目标页面：优先使用显式页面，缺省时按引导标识推导。
  String? effectivePage() {
    final activeGuide = effectiveGuide();
    var resolved = page;
    if ((resolved == null || resolved == 'homePage') &&
        activeGuide != null &&
        activeGuide.isNotEmpty) {
      resolved = switch (activeGuide) {
        'payment' => RoutePaths.fineInformation,
        'quick' || 'flow' || 'evidence' || 'video' =>
          RoutePaths.userOffenseListPage,
        _ => resolved,
      };
    }
    return resolved;
  }
}
