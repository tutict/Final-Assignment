
import 'package:final_assignment_front/config/navigation/shell_navigation.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/progress_detail.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/app_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('driver sidebar shows task groups and not logout', (tester) async {
    await tester.pumpWidget(_host(AppSidebar(
      groups: userShellGroups(),
      activePath: 'homePage',
      collapsed: false,
      brandMark: '办',
      brandTitle: '交通违法办事',
      onToggle: () {},
      onSelect: (_) {},
    )));

    expect(find.text('退出登录'), findsNothing);
    expect(find.text('违法行为'), findsNothing);
    for (final label in ['首页', '我的违法', '缴费', '申诉', '我的车辆', '消息', '地图', '个人资料', '咨询反馈', '设置']) {
      await _show(tester, label);
    }
    expect(_itemHeights(tester), everyElement(48));
  });

  testWidgets('appeal reviewer sidebar stays narrow', (tester) async {
    await tester.pumpWidget(_host(AppSidebar(
      groups: managerShellGroups(superAdmin: false, appealReviewer: true),
      activePath: 'homePage',
      collapsed: false,
      brandMark: '管',
      brandTitle: '交通违法管理',
      onToggle: () {},
      onSelect: (_) {},
    )));

    for (final label in ['首页', '申诉', '消息', '个人资料', '设置']) {
      await _show(tester, label);
    }
    expect(find.text('违法行为'), findsNothing);
    expect(find.text('缴费流水'), findsNothing);
    expect(find.text('系统'), findsNothing);
    expect(find.text('退出登录'), findsNothing);
  });

  testWidgets('admin sidebar has business and oversight without system or map', (tester) async {
    await tester.pumpWidget(_host(AppSidebar(
      groups: managerShellGroups(superAdmin: false, appealReviewer: false),
      activePath: 'homePage',
      collapsed: false,
      brandMark: '管',
      brandTitle: '交通违法管理',
      onToggle: () {},
      onSelect: (_) {},
    )));

    await _show(tester, '违法行为');
    await _show(tester, '缴费流水');
    await _show(tester, 'RAG 资料');
    expect(find.text('地图'), findsNothing);
    expect(find.text('系统'), findsNothing);
    expect(find.text('操作日志'), findsNothing);
    expect(find.text('退出登录'), findsNothing);
  });

  testWidgets('super admin system group starts collapsed and can expand', (tester) async {
    await tester.pumpWidget(_host(AppSidebar(
      groups: managerShellGroups(superAdmin: true, appealReviewer: false),
      activePath: 'homePage',
      collapsed: false,
      brandMark: '管',
      brandTitle: '交通违法管理',
      onToggle: () {},
      onSelect: (_) {},
    )));

    await _show(tester, '违法行为');
    expect(find.text('操作日志'), findsNothing);
    await tester.scrollUntilVisible(find.text('系统'), 400, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('系统'));
    await tester.pump();
    await _show(tester, '操作日志');
    await _show(tester, '备份恢复');
    expect(find.text('退出登录'), findsNothing);
  });

  testWidgets('collapsed sidebar keeps labels on tooltips', (tester) async {
    await tester.pumpWidget(_host(AppSidebar(
      groups: userShellGroups(),
      activePath: 'homePage',
      collapsed: true,
      brandMark: '办',
      brandTitle: '交通违法办事',
      onToggle: () {},
      onSelect: (_) {},
    )));

    expect(find.text('我的违法'), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => widget is Tooltip && widget.message == '我的违法'),
      findsOneWidget,
    );
  });

  testWidgets('missing progress detail explains itself', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MissingProgressDetailPage()));
    expect(find.text('没有找到这条进度'), findsOneWidget);
    expect(find.textContaining('原始错误'), findsOneWidget);
    expect(find.text('返回'), findsOneWidget);
  });
}


Finder _item(String label) {
  return find.descendant(
    of: find.byWidgetPredicate((widget) => widget is SizedBox && widget.height == 48),
    matching: find.text(label),
  );
}

Future<void> _show(WidgetTester tester, String label) async {
  final finder = _item(label);
  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  expect(finder, findsOneWidget, reason: label);
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 248, height: 2400, child: child),
    ),
  );
}

List<double> _itemHeights(WidgetTester tester) {
  return tester
      .widgetList<SizedBox>(find.byType(SizedBox))
      .where((box) => box.height == 48)
      .map((box) => box.height!)
      .toList();
}
