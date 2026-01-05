// lib/domain/usecases/get_current_user_usecase.dart
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  AuthEntity? call(String userId) {
    return repository.getCurrentUser(userId);
  }
}
