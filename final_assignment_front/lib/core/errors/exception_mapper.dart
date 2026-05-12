import 'app_exception.dart';

class ExceptionMapper {
  const ExceptionMapper._();

  static AppException map(Object error) => AppException.fromError(error);
}
