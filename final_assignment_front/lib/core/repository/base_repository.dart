import '../errors/exception_mapper.dart';

abstract class BaseRepository {
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw ExceptionMapper.map(error);
    }
  }
}
