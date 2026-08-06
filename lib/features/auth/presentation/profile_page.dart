import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/session_store.dart';
import '../../../shared/services/theme_store.dart';
import '../data/auth_service.dart';
import 'auth_entry_page.dart';
import '../../home/presentation/home_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const routeName = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();
  Future<UserProfile>? _profileFuture;
  bool _hasSession = true;
  bool _isSaving = false;
  bool _removeSelectedProfilePhoto = false;
  XFile? _selectedProfilePhoto;
  Uint8List? _selectedProfilePhotoBytes;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    await SessionStore.instance.load();
    if (!mounted) return;

    if (SessionStore.instance.accessToken == null) {
      setState(() {
        _hasSession = false;
      });
      return;
    }

    setState(() {
      _hasSession = true;
      _profileFuture = _authService.fetchProfile();
    });
  }

  void _populateControllers(UserProfile profile) {
    if (_currentProfile?.id == profile.id &&
        _currentProfile?.username == profile.username &&
        _currentProfile?.email == profile.email &&
        _currentProfile?.firstName == profile.firstName &&
        _currentProfile?.lastName == profile.lastName &&
        _currentProfile?.phoneNumber == profile.phoneNumber &&
        _currentProfile?.profilePhotoUrl == profile.profilePhotoUrl) {
      return;
    }

    _currentProfile = profile;
    _usernameController.text = profile.username;
    _emailController.text = profile.email;
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _phoneController.text = profile.phoneNumber;
    _selectedProfilePhoto = null;
    _selectedProfilePhotoBytes = null;
    _removeSelectedProfilePhoto = false;
  }

  Future<void> _goHome() async {
    Navigator.pushNamedAndRemoveUntil(context, AuthEntryPage.routeName, (route) => false);
  }

  Future<void> _goBack() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    await Navigator.pushNamedAndRemoveUntil(
      context,
      _hasSession ? HomePage.routeName : AuthEntryPage.routeName,
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await SessionStore.instance.clear();
    if (!mounted) return;
    await _goHome();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This will remove your profile and reports from the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
      await _goHome();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  Future<void> _toggleTheme() async {
    await ThemeStore.instance.toggleTheme();
  }

  Future<void> _pickProfilePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    final imageBytes = await image.readAsBytes();

    setState(() {
      _selectedProfilePhoto = image;
      _selectedProfilePhotoBytes = imageBytes;
      _removeSelectedProfilePhoto = false;
    });
  }

  void _removeProfilePhoto() {
    setState(() {
      _selectedProfilePhoto = null;
      _selectedProfilePhotoBytes = null;
      _removeSelectedProfilePhoto = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedProfile = await _authService.updateProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profilePhotoBytes: _selectedProfilePhotoBytes,
        profilePhotoName: _selectedProfilePhoto?.name,
        removeProfilePhoto: _removeSelectedProfilePhoto,
      );

      if (!mounted) return;

      setState(() {
        _currentProfile = updatedProfile;
        _selectedProfilePhoto = null;
        _selectedProfilePhotoBytes = null;
        _removeSelectedProfilePhoto = false;
        _profileFuture = Future.value(updatedProfile);
      });
      _populateControllers(updatedProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile update failed: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: const Text('Profile'),
      ),
      body: SafeArea(
        top: false,
        child: !_hasSession
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_circle_outlined, size: 72, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'You are not logged in.',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to see your profile, logout, or delete your account.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(context, LoginPage.routeName),
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              )
            : _profileFuture == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<UserProfile>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        final error = snapshot.error;
                        if (error is ApiException && error.statusCode == 401) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 72,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Session expired.',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please log in again to load your profile.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: () => Navigator.pushNamed(context, LoginPage.routeName),
                                    child: const Text('Go to Login'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Center(child: Text('Failed to load profile: ${snapshot.error}'));
                      }

                      final profile = snapshot.data;
                      if (profile == null) {
                        return const Center(child: Text('No profile data available.'));
                      }

                      _populateControllers(profile);
                      final initials = _initialsFor(profile.fullName.isEmpty ? profile.username : profile.fullName);
                      final profileImageProvider = _buildProfileImageProvider(profile);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: _pickProfilePhoto,
                                    borderRadius: BorderRadius.circular(40),
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 34,
                                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                                          backgroundImage: profileImageProvider,
                                          child: profileImageProvider == null
                                              ? Text(
                                                  initials,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _displayName(),
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _emailController.text.trim().isEmpty ? profile.email : _emailController.text.trim(),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _RoleChip(label: profile.role),
                                            _RoleChip(
                                              label: _phoneController.text.trim().isEmpty
                                                  ? 'No phone'
                                                  : _phoneController.text.trim(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Profile Details', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Enter a username';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailController,
                                    onChanged: (_) => setState(() {}),
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Enter an email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _firstNameController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'First name',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _lastNameController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'Last name',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneController,
                                    onChanged: (_) => setState(() {}),
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone number',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.security_outlined, color: theme.colorScheme.primary),
                                    title: const Text('Role'),
                                    subtitle: Text(profile.role),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isSaving ? null : _pickProfilePhoto,
                                          icon: const Icon(Icons.photo_library_outlined),
                                          label: const Text('Change Photo'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isSaving ||
                                                  (_selectedProfilePhoto == null &&
                                                      profile.profilePhotoUrl.isEmpty)
                                              ? null
                                              : _removeProfilePhoto,
                                          icon: const Icon(Icons.delete_outline),
                                          label: const Text('Remove Photo'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    icon: const Icon(Icons.save_outlined),
                                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Appearance', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Card(
                              child: SwitchListTile.adaptive(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                title: const Text('Dark mode'),
                                subtitle: const Text('Switch between light and dark background.'),
                                value: ThemeStore.instance.isDarkMode,
                                onChanged: (_) => _toggleTheme(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Account Info', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: Icons.person_outline,
                              title: 'Username',
                              value: _usernameController.text,
                            ),
                            _InfoCard(
                              icon: Icons.badge_outlined,
                              title: 'Full name',
                              value: _displayFullName(),
                            ),
                            _InfoCard(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              value: _emailController.text,
                            ),
                            _InfoCard(
                              icon: Icons.phone_outlined,
                              title: 'Phone number',
                              value: _phoneController.text.trim().isEmpty ? 'Not set' : _phoneController.text.trim(),
                            ),
                            _InfoCard(
                              icon: Icons.security_outlined,
                              title: 'Role',
                              value: profile.role,
                            ),
                            const SizedBox(height: 20),
                            Text('Actions', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSecondaryContainer,
                                backgroundColor: theme.colorScheme.secondaryContainer,
                              ),
                              onPressed: _deleteAccount,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete Account'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _initialsFor(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  ImageProvider<Object>? _buildProfileImageProvider(UserProfile profile) {
    if (_removeSelectedProfilePhoto) {
      return null;
    }

    if (_selectedProfilePhotoBytes != null) {
      return MemoryImage(_selectedProfilePhotoBytes!);
    }

    if (profile.profilePhotoUrl.isEmpty) {
      return null;
    }

    return NetworkImage(_authService.resolveMediaUrl(profile.profilePhotoUrl));
  }

  String _displayFullName() {
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    return fullName.isEmpty ? 'Not set' : fullName;
  }

  String _displayName() {
    final fullName = _displayFullName();
    if (fullName != 'Not set') {
      return fullName;
    }
    return _usernameController.text.trim().isEmpty ? 'User' : _usernameController.text.trim();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value, style: theme.textTheme.bodyLarge),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.black.withValues(alpha: 0.22),
      labelStyle: const TextStyle(color: Colors.white),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    );
  }
}
