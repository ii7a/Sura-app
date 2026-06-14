import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  String? _birthDate;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  File? _bannerImage;
  bool _isSaving = false;

  String? _existingAvatarUrl;
  String? _existingBannerUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();

    // Load current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameController.text = user.name;
        _bioController.text = user.bio;
        _locationController.text = user.location ?? '';
        _phoneController.text = user.phone ?? '';
        _birthDate = user.birthDate;
        // Only use existing URLs if the file actually exists (for local paths)
        if (user.avatarUrl != null) {
          if (user.avatarUrl!.startsWith('/')) {
            if (File(user.avatarUrl!).existsSync()) _existingAvatarUrl = user.avatarUrl;
          } else {
            _existingAvatarUrl = user.avatarUrl;
          }
        }
        if (user.bannerUrl != null) {
          if (user.bannerUrl!.startsWith('/')) {
            if (File(user.bannerUrl!).existsSync()) _existingBannerUrl = user.bannerUrl;
          } else {
            _existingBannerUrl = user.bannerUrl;
          }
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
      if (picked != null) {
        debugPrint('Profile image picked: ${picked.path}');
        setState(() => _profileImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickBannerImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (picked != null) {
        debugPrint('Banner image picked: ${picked.path}');
        setState(() => _bannerImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('Error picking banner image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final storage = StorageService();
      final phoneText = _phoneController.text.trim();
      final locationText = _locationController.text.trim();
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': phoneText.isEmpty ? null : phoneText,
        'location': locationText.isEmpty ? null : locationText,
        'birthDate': _birthDate,
      };

      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        final initials = name.split(' ').map((w) => w[0]).take(2).join().toUpperCase();
        updates['avatarInitials'] = initials;
      }

      // Upload picked images to Cloudinary (via StorageService) and persist
      // the returned URLs in Firestore.
      if (_profileImage != null) {
        final url = await storage.uploadImage(
          _profileImage!,
          'users/$uid/avatar.jpg',
        );
        updates['avatarUrl'] = url;
      }

      if (_bannerImage != null) {
        final url = await storage.uploadImage(
          _bannerImage!,
          'users/$uid/banner.jpg',
        );
        updates['bannerUrl'] = url;
      }

      await firestore.updateUser(uid, updates);
      debugPrint('Firestore updated successfully');

      if (mounted) {
        Navigator.of(context).pop({'updated': true});
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: font(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ),
        leadingWidth: 80,
        centerTitle: true,
        title: Text(
          l10n.editProfile,
          style: font(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    l10n.save,
                    style: font(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image area
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner - tappable to change
                GestureDetector(
                  onTap: _pickBannerImage,
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: _bannerImage != null
                        ? Image.file(_bannerImage!, fit: BoxFit.cover, width: double.infinity, height: 140)
                        : _existingBannerUrl != null
                            ? (_existingBannerUrl!.startsWith('/')
                                ? Image.file(File(_existingBannerUrl!), fit: BoxFit.cover, width: double.infinity, height: 140)
                                : Image.network(_existingBannerUrl!, fit: BoxFit.cover, width: double.infinity, height: 140))
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF0a0a2e),
                                      Color(0xFF1a1a4e),
                                      Color(0xFF0d0d1a),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 32,
                                  ),
                                ),
                              ),
                  ),
                ),

                // Profile avatar overlapping banner - tappable to change
                Positioned(
                  left: 16,
                  bottom: -36,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.dark, width: 3),
                      ),
                      child: _profileImage != null
                          ? CircleAvatar(
                              radius: 33,
                              backgroundImage: FileImage(_profileImage!),
                              backgroundColor: AppColors.navy,
                            )
                          : _existingAvatarUrl != null
                              ? CircleAvatar(
                                  radius: 33,
                                  backgroundImage: _existingAvatarUrl!.startsWith('/')
                                      ? FileImage(File(_existingAvatarUrl!))
                                      : NetworkImage(_existingAvatarUrl!) as ImageProvider,
                                  backgroundColor: AppColors.navy,
                                )
                              : CircleAvatar(
                                  radius: 33,
                                  backgroundColor: AppColors.navy,
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.white,
                                    size: 24,
                                  ),
                                ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Form fields
            _EditField(
              label: l10n.nameLabel,
              controller: _nameController,
            ),
            const _FieldDivider(),
            _EditField(
              label: l10n.bioLabel,
              controller: _bioController,
              maxLines: 3,
            ),
            const _FieldDivider(),
            const SizedBox(height: 16),
            _EditField(
              label: l10n.locationLabel,
              controller: _locationController,
              trailing: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary, size: 22),
            ),
            const _FieldDivider(),
            _EditField(
              label: 'Phone',
              controller: _phoneController,
              hint: '+966 …',
              keyboardType: TextInputType.phone,
            ),
            const _FieldDivider(),
            // Birth date — tappable, opens a native date picker
            InkWell(
              onTap: _pickBirthDate,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        l10n.birthDate,
                        style: font(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _birthDate ?? l10n.addBirthDate,
                        style: font(
                          color: _birthDate != null
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary, size: 22),
                  ],
                ),
              ),
            ),
            const _FieldDivider(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate != null
        ? DateTime.tryParse(_birthDate!) ?? DateTime(2000)
        : DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Store as ISO 8601 yyyy-MM-dd so it round-trips cleanly through
        // Firestore as a plain string.
        _birthDate =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.trailing,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final Widget? trailing;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 10 : 0),
            child: SizedBox(
              width: 90,
              child: Text(
                label,
                style: font(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: font(
                color: AppColors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint ?? '',
                hintStyle: font(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Colors.white12,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}

