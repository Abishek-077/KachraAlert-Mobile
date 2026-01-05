// lib/domain/usecases/login_usecase.dart
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthEntity?> call(String email, String password) {
    return repository.login(email.trim(), password);
  }
}
