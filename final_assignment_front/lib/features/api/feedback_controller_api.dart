import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultFeedbackApiClient = ApiClient();

class FeedbackControllerApi with BaseApiClient {
  FeedbackControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultFeedbackApiClient;

  @override
  final ApiClient apiClient;

  Future<Map<String, dynamic>> createFeedback({
    required Map<String, dynamic> body,
  }) {
    return requestMap(
      'POST',
      '/api/feedback',
      body: body,
      contentType: BaseApiClient.defaultContentType,
      successStatusCodes: const {200, 201},
    );
  }

  Future<List<Map<String, dynamic>>> listFeedback() {
    return requestList<Map<String, dynamic>>(
      'GET',
      '/api/feedback',
      (json) => json,
    );
  }

  Future<Map<String, dynamic>> updateFeedback({
    required int feedbackId,
    required Map<String, dynamic> body,
  }) {
    return requestMap(
      'PUT',
      '/api/feedback/$feedbackId',
      body: body,
      contentType: BaseApiClient.defaultContentType,
    );
  }
}
