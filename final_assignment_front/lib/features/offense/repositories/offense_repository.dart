import 'package:final_assignment_front/core/repository/base_repository.dart';
import 'package:final_assignment_front/features/api/offense_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';

abstract class OffenseRepository {
  Future<void> initializeWithJwt();

  Future<List<OffenseInformation>> listOffenses();

  Future<Map<String, dynamic>> getOffenseDetails({
    required int offenseId,
  });

  Future<List<OffenseInformation>> listOffensesByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  });
}

class OffenseRepositoryImpl extends BaseRepository
    implements OffenseRepository {
  OffenseRepositoryImpl(this._api);

  final OffenseControllerApi _api;

  @override
  Future<void> initializeWithJwt() {
    return guard(() => _api.initializeWithJwt());
  }

  @override
  Future<List<OffenseInformation>> listOffenses() {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.listOffenses();
    });
  }

  @override
  Future<Map<String, dynamic>> getOffenseDetails({
    required int offenseId,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.getOffenseDetails(offenseId: offenseId);
    });
  }

  @override
  Future<List<OffenseInformation>> listOffensesByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.listOffensesByStatus(
        processStatus: processStatus,
        page: page,
        size: size,
      );
    });
  }
}
