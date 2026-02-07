import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/ui/snackbar.dart';
import '../../../../core/utils/media_permissions.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/admin_user_model.dart';
import '../providers/admin_user_providers.dart';

class AdminUserFormScreen extends ConsumerStatefulWidget {
  const AdminUserFormScreen({super.key, this.existing});

  final AdminUser? existing;

  @override
  ConsumerState<AdminUserFormScreen> createState() =>
      _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends ConsumerState<AdminUserFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _societyController;
  late final TextEditingController _buildingController;
  late final TextEditingController _apartmentController;

  String _accountType = 'resident';
  bool _saving = false;
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _accountType = existing?.accountType ?? 'resident';
    _nameController = TextEditingController(text: existing?.name ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _passwordController = TextEditingController();
    _societyController = TextEditingController(text: existing?.society ?? '');
    _buildingController = TextEditingController(text: existing?.building ?? '');
    _apartmentController = TextEditingController(text: existing?.apartment ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _societyController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    await MediaPermissions.requestPhotoVideoAccess(context);
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
    });
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final isEdit = widget.existing != null;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final society = _societyController.text.trim();
    final building = _buildingController.text.trim();
    final apartment = _apartmentController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        society.isEmpty ||
        building.isEmpty ||
        apartment.isEmpty ||
        (!isEdit && password.isEmpty)) {
      AppSnack.show(context, 'Please fill in all required fields.', error: true);
      return;
    }

    if (!isEdit && password.length < 6) {
      AppSnack.show(context, 'Password must be at least 6 characters.', error: true);
      return;
    }

    try {
      setState(() => _saving = true);
      final notifier = ref.read(adminUsersProvider.notifier);
      if (isEdit) {
        await notifier.update(
          id: widget.existing!.id,
          accountType: _accountType,
          name: name,
          email: email,
          phone: phone,
          password: password.isEmpty ? null : password,
          society: society,
          building: building,
          apartment: apartment,
          imageBytes: _imageBytes,
          imageName: _imageName,
        );
      } else {
        await notifier.create(
          accountType: _accountType,
          name: name,
          email: email,
          phone: phone,
          password: password,
          society: society,
          building: building,
          apartment: apartment,
          imageBytes: _imageBytes,
          imageName: _imageName,
        );
      }

      if (!mounted) return;
      AppSnack.show(
        context,
        isEdit ? 'User updated successfully.' : 'User created successfully.',
        error: false,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(context, 'Failed to save user: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    final apiBase = ref.watch(apiBaseUrlProvider);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final token = auth?.session?.accessToken;
    final avatarHeaders =
        token?.isNotEmpty == true ? {'Authorization': 'Bearer $token'} : null;
    final existingAvatar = resolveMediaUrl(
      apiBase,
      widget.existing?.profileImageUrl,
    );

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                DelayedReveal(
                  delay: const Duration(milliseconds: 60),
                  child: Row(
                    children: [
                      Text(
                        isEdit ? 'Edit User' : 'Create User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DelayedReveal(
                  delay: const Duration(milliseconds: 140),
                  child: KCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.tealEmeraldGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child:
                              const Icon(Icons.person_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Update account' : 'Create new account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All fields are synced to the live backend.',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Account type'),
                const SizedBox(height: 8),
                KCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    value: _accountType,
                    decoration: const InputDecoration(border: InputBorder.none),
                    items: const [
                      DropdownMenuItem(
                        value: 'resident',
                        child: Text('Resident'),
                      ),
                      DropdownMenuItem(
                        value: 'admin_driver',
                        child: Text('Admin / Driver'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _accountType = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Full name'),
                const SizedBox(height: 8),
                _TextFieldCard(
                  controller: _nameController,
                  hint: 'Enter full name',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Email'),
                const SizedBox(height: 8),
                _TextFieldCard(
                  controller: _emailController,
                  hint: 'name@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Phone'),
                const SizedBox(height: 8),
                _TextFieldCard(
                  controller: _phoneController,
                  hint: '+977 98xxxxxxx',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _SectionLabel(
                  label: isEdit ? 'Reset password (optional)' : 'Password',
                ),
                const SizedBox(height: 8),
                _TextFieldCard(
                  controller: _passwordController,
                  hint:
                      isEdit ? 'Leave blank to keep current' : 'Create a password',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Society'),
                const SizedBox(height: 8),
                _TextFieldCard(
                  controller: _societyController,
                  hint: 'Society name',
                  icon: Icons.apartment_outlined,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Building'),
                const SizedBox(height: 8),
                _TextFieldCard(
                  controller: _buildingController,
                  hint: 'Building name',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Apartment'),
                const SizedBox(height: 8),
                _TextFieldCard(
                  controller: _apartmentController,
                  hint: 'Apartment number',
                  icon: Icons.meeting_room_outlined,
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Profile image (optional)'),
                const SizedBox(height: 8),
                KCard(
                  padding: const EdgeInsets.all(14),
                  onTap: _pickImage,
                  child: _imageBytes == null
                      ? Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.photo_camera_outlined,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tap to upload photo',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Use a clear headshot for best results.',
                                    style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (existingAvatar != null)
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: cs.primary.withOpacity(0.12),
                                foregroundImage: NetworkImage(
                                  existingAvatar,
                                  headers: avatarHeaders,
                                ),
                              ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.attachment_rounded, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _imageName ?? 'profile.jpg',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _saving ? null : _save,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_saving) ...[
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  isEdit ? 'Save Changes' : 'Create User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(isEdit ? Icons.check_rounded : Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: cs.onSurface.withOpacity(0.55),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        fontSize: 12,
      ),
    );
  }
}

class _TextFieldCard extends StatelessWidget {
  const _TextFieldCard({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.45)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
