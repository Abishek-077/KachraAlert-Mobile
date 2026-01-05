// lib/features/auth/data/providers/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kachra_alert/features/auth/data/datasources/local/auth_local_datasource.dart';

import 'package:kachra_alert/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kachra_alert/features/auth/domain/repositories/auth_repository.dart';
import 'package:kachra_alert/features/auth/domain/usecases/login_usecase.dart';
import 'package:kachra_alert/features/auth/domain/usecases/register_usecase.dart';
import 'package:kachra_alert/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kachra_alert/features/auth/domain/usecases/get_current_user_usecase.dart';

// Local Datasource Provider (already exists in auth_local_datasource.dart)
final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  // This uses hiveServiceProvider from core
  // Make sure hiveServiceProvider is defined and initialized
  throw UnimplementedError(
    'Make sure authLocalDatasourceProvider is defined in auth_local_datasource.dart',
  );
});

// Repository Provider - uses the datasource
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authLocalDatasourceProvider);
  return AuthRepositoryImpl(datasource); // ← Matches your constructor
});

// Use Case Providers
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LoginUseCase(repo);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repo);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repo);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repo);
});
