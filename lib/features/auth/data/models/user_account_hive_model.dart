import 'package:hive/hive.dart';

part 'user_account_hive_model.g.dart';

@HiveType(typeId: 13)
class UserAccountHiveModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String password; // local-only for now (later hash in backend)

  @HiveField(3)
  final String role; // 'resident' | 'admin_driver'

  UserAccountHiveModel({
    required this.userId,
    required this.email,
    required this.password,
    required this.role,
  });
}
