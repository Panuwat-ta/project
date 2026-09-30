import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_mapper.dart';

/// Remote operations that are implemented by the current backend.
abstract class SettingsRemoteDataSource {
  /// DELETE /users/me — soft-deletes the authenticated account after password confirmation.
  Future<void> deleteAccount(String password);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<void> deleteAccount(String password) async {
    try {
      await dio.delete<void>(
        ApiEndpoints.usersMe,
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
