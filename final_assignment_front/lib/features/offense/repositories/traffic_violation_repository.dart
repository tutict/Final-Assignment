import 'package:final_assignment_front/core/repository/base_repository.dart';
import 'package:final_assignment_front/features/api/traffic_violation_controller_api.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';

abstract class TrafficViolationRepository {
  Future<void> initializeWithJwt();

  Future<List<OffenseInformation>> getViolations();

  Future<Map<String, dynamic>> getViolationDetails({
    required int offenseId,
  });

  Future<List<OffenseInformation>> getViolationsByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  });
}

class TrafficViolationRepositoryImpl extends BaseRepository
    implements TrafficViolationRepository {
  TrafficViolationRepositoryImpl(this._api);

  final TrafficViolationControllerApi _api;

  @override
  Future<void> initializeWithJwt() {
    return guard(() => _api.initializeWithJwt());
  }

  @override
  Future<List<OffenseInformation>> getViolations() {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.apiViolationsGet();
    });
  }

  @override
  Future<Map<String, dynamic>> getViolationDetails({
    required int offenseId,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.apiViolationsOffenseIdGet(offenseId: offenseId);
    });
  }

  @override
  Future<List<OffenseInformation>> getViolationsByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.apiViolationsStatusGet(
        processStatus: processStatus,
        page: page,
        size: size,
      );
    });
  }
}
