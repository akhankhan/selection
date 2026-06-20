import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme_extension.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  File? _pickedImage;
  String? _existingPhotoUrl;
  String _initialName = '';
  bool _isSaving = false;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _initialName = user?.displayName ?? '';
    _nameController.text = _initialName;
    _existingPhotoUrl = user?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final nameChanged = _nameController.text.trim() != _initialName;
    final photoChanged = _pickedImage != null || _removePhoto;
    return nameChanged || photoChanged;
  }

  Future<void> _upsertUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      final snap = await ref.get();
      final profile = <String, dynamic>{
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'lastSignInAt': FieldValue.serverTimestamp(),
      };
      if (!snap.exists) {
        profile['createdAt'] = FieldValue.serverTimestamp();
        await ref.set(profile);
      } else {
        await ref.update(profile);
      }
    } catch (e) {
      debugPrint('[Firestore] profile update failed: $e');
    }
  }

  Future<void> _showPhotoOptions() async {
    final hasPhoto = _pickedImage != null ||
        (!_removePhoto &&
            (_existingPhotoUrl != null ||
                FirebaseAuth.instance.currentUser?.photoURL != null));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final appTheme = sheetContext.appTheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: appTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Profile photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appTheme.navyText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to update your photo',
                  style: TextStyle(fontSize: 13, color: appTheme.subtitle),
                ),
                const SizedBox(height: 20),
                _PhotoOptionTile(
                  icon: Icons.photo_library_rounded,
                  iconColor: sheetContext.brandBlue,
                  title: 'Choose from gallery',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _PhotoOptionTile(
                  icon: Icons.photo_camera_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Take a photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (hasPhoto)
                  _PhotoOptionTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.red,
                    title: 'Remove photo',
                    titleColor: Colors.red,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _pickedImage = null;
                        _removePhoto = true;
                      });
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() {
        _pickedImage = File(file.path);
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  Future<String?> _uploadProfilePhoto(User user, File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('users/${user.uid}/profile.jpg');
    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      String? photoUrl = user.photoURL;

      if (_pickedImage != null) {
        photoUrl = await _uploadProfilePhoto(user, _pickedImage!);
      } else if (_removePhoto) {
        photoUrl = null;
        try {
          await FirebaseStorage.instance
              .ref()
              .child('users/${user.uid}/profile.jpg')
              .delete();
        } catch (_) {}
      }

      await user.updateDisplayName(name);
      await user.updatePhotoURL(photoUrl);
      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser != null) {
        await _upsertUserDoc(updatedUser);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider? _avatarImage() {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    if (!_removePhoto && _existingPhotoUrl != null) {
      return NetworkImage(_existingPhotoUrl!);
    }
    return null;
  }

  String _avatarInitial() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    final email = FirebaseAuth.instance.currentUser?.email ?? 'U';
    return email[0].toUpperCase();
  }

  String _displayNamePreview() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name;
    return 'Add your name';
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? prefixIcon,
    bool readOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: readOnly ? appTheme.sectionBg : colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: appTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: appTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: context.brandBlue,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: appTheme.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;
    final user = FirebaseAuth.instance.currentUser;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.headerSurface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving || !_hasChanges ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _hasChanges
                    ? context.brandBlue
                    : appTheme.subtitle,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: appTheme.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.brandBlue.withValues(alpha: 0.1),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isSaving ? null : _showPhotoOptions,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor:
                                      context.brandBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  backgroundImage: _avatarImage(),
                                  child: _avatarImage() == null
                                      ? Text(
                                          _avatarInitial(),
                                          style: TextStyle(
                                            color: context.brandBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 38,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: context.brandBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.brandBlue
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayNamePreview(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _nameController.text.trim().isEmpty
                                ? appTheme.subtitle
                                : appTheme.navyText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: appTheme.subtitle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _showPhotoOptions,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Change profile photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.brandBlue,
                            side: BorderSide(color: appTheme.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Account Details',
                      style: TextStyle(
                        color: context.brandBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: colorScheme.surface,
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              enabled: !_isSaving,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              decoration: _fieldDecoration(
                                context,
                                label: 'Display name',
                                hint: 'How should we call you?',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: appTheme.subtitle,
                                ),
                              ),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) return 'Name is required';
                                if (name.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              initialValue: user?.email ?? '',
                              readOnly: true,
                              decoration: _fieldDecoration(
                                context,
                                label: 'Email address',
                                readOnly: true,
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: appTheme.subtitle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: appTheme.sectionBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: appTheme.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: appTheme.subtitle,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your email is linked to your account and cannot be changed here.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: appTheme.subtitle,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving || !_hasChanges ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: context.brandBlue,
                  disabledBackgroundColor:
                      context.brandBlue.withValues(alpha: 0.5),
                  disabledForegroundColor: colorScheme.onPrimary.withValues(
                    alpha: 0.7,
                  ),
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Save changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoOptionTile extends StatelessWidget {
  const _PhotoOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? appTheme.navyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
