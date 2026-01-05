// lib/domain/usecases/register_usecase.dart
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthEntity> call({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    final exists = await repository.emailExists(email.trim());
    if (exists) {
      throw Exception('Email already registered');
    }

    return repository.register(
      fullName: fullName,
      email: email.trim(),
      password: password,
      phone: phone,
      address: address,
    );
  }
}
