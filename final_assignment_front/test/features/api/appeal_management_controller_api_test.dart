import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// 申诉列表页此前按违法记录逐条查询且只扫描前 20 条违法记录，
/// 现在直接分页拉取全部申诉，这里固定翻页终止条件。
class _FakeAppealManagementApi extends AppealManagementControllerApi {
  _FakeAppealManagementApi(this.pageRows);

  final Map<int, int> pageRows;
  final List<int> requestedPages = [];

  @override
  Future<List<AppealRecordModel>> listAllAppeals({
    int page = 1,
    int size = 20,
  }) async {
    requestedPages.add(page);
    final count = pageRows[page] ?? 0;
    return List.generate(
      count,
      (index) => AppealRecordModel(appealId: page * 1000 + index),
    );
  }
}

void main() {
  test('listAllAppealsPaged 逐页拉取直到不足一页', () async {
    final api = _FakeAppealManagementApi({1: 100, 2: 45});

    final appeals = await api.listAllAppealsPaged();

    expect(api.requestedPages, [1, 2]);
    expect(appeals, hasLength(145));
  });

  test('listAllAppealsPaged 首页不足时立即停止', () async {
    final api = _FakeAppealManagementApi({1: 12});

    final appeals = await api.listAllAppealsPaged();

    expect(api.requestedPages, [1]);
    expect(appeals, hasLength(12));
  });
}
