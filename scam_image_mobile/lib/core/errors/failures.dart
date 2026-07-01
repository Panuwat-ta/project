import 'package:equatable/equatable.dart';

/// Base class for all domain-layer failures.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure originating from a non-2xx HTTP response from the server.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Failure caused by a network connectivity issue (no internet, timeout, etc.).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้']);
}

/// Failure related to authentication (invalid credentials, token expired, etc.).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'กรุณาเข้าสู่ระบบใหม่อีกครั้ง']);
}

/// Failure caused by reading from or writing to local cache / secure storage.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'เกิดข้อผิดพลาดในการจัดเก็บข้อมูล']);
}

/// Failure caused by invalid user input or request data.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
