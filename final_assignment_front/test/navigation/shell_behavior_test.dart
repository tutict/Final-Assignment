
import 'package:final_assignment_front/core/theme/theme_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/pages/main_process/manager_business_page_chrome.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/components/progress_message_page.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/motion.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark mode preference is still there after a fresh load', () async {
    SharedPreferences.setMockInitialValues({'isDarkMode': true, 'selectedStyle': 'Material'});
    final controller = ThemeController();
    await controller.load();
    expect(controller.isDark, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selectedStyle'), 'Material');
  });

  testWidgets('reduced motion removes travel time', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox.shrink();
      }),
    ));
    expect(shellMotion(context), Duration.zero);
  });

  testWidgets('manager table loading, error and empty each explain the next step', (tester) async {
    await tester.pumpWidget(_chrome(isLoading: true));
    expect(find.text('正在加载业务数据'), findsOneWidget);
    expect(find.text('请稍候，加载完成后会显示在这里。'), findsOneWidget);
    expect(find.text('表格内容'), findsNothing);

    await tester.pumpWidget(_chrome(errorMessage: '列表没有加载成功，请重试。'));
    expect(find.text('列表没有加载成功，请重试。'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('表格内容'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);

    await tester.pumpWidget(_chrome(emptyMessage: '暂无记录'));
    expect(find.text('暂无记录'), findsOneWidget);
    expect(find.text('业务数据同步后会显示在这里。'), findsOneWidget);
    expect(find.text('表格内容'), findsNothing);
  });

  testWidgets('wide messages stay in place and narrow messages open the detail route', (tester) async {
    var opened = false;
    Future<void> mount(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgressMessagePageBody(
            title: '消息',
            subtitle: '处理进度',
            roleLabel: '驾驶员',
            items: [
              ProgressItem(
                id: 7,
                title: '申诉进度',
                status: 'Processing',
                submitTime: DateTime(2026, 9, 1),
                username: 'driver',
              ),
            ],
            totalCount: 1,
            statusCategories: const ['Processing'],
            isLoading: false,
            errorMessage: '',
            hasAccess: true,
            emptyMessage: '暂无消息',
            businessContextBuilder: (_) => '申诉',
            onStatusSelected: (_) {},
            onDateRangePressed: () {},
            onClearFilters: () {},
            onOpen: (_) => opened = true,
          ),
        ),
      ));
    }

    await mount(const Size(1280, 900));
    await tester.tap(find.text('申诉进度'));
    await tester.pump();
    expect(opened, isFalse);
    expect(find.text('进度详情'), findsOneWidget);

    opened = false;
    await mount(const Size(800, 900));
    await tester.tap(find.text('申诉进度'));
    await tester.pump();
    expect(opened, isTrue);
    expect(find.text('进度详情'), findsNothing);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('message filter chip can be cleared', (tester) async {
    var cleared = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProgressMessagePageBody(
          title: '消息',
          subtitle: '处理进度',
          roleLabel: '驾驶员',
          items: const [],
          totalCount: 0,
          statusCategories: const ['Processing'],
          selectedStatus: 'Processing',
          isLoading: false,
          errorMessage: '',
          hasAccess: true,
          emptyMessage: '没有符合筛选的消息。清除筛选后再看。',
          businessContextBuilder: (_) => '',
          onStatusSelected: (_) {},
          onDateRangePressed: () {},
          onClearFilters: () => cleared = true,
          onOpen: (_) {},
        ),
      ),
    ));

    expect(find.text('处理中'), findsWidgets);
    await tester.tap(find.byTooltip('清除筛选'));
    expect(cleared, isTrue);
  });
}

Widget _chrome({bool isLoading = false, String errorMessage = '', String emptyMessage = ''}) {
  return MaterialApp(
    home: Scaffold(
      body: ManagerBusinessPageChrome(
        icon: Icons.list_alt,
        title: '违法行为',
        subtitle: '检索违法记录',
        totalCount: 0,
        visibleCount: 0,
        searchBar: const SizedBox.shrink(),
        isLoading: isLoading,
        errorMessage: errorMessage,
        emptyMessage: emptyMessage,
        onRetry: () {},
        child: const Text('表格内容'),
      ),
    ),
  );
}
