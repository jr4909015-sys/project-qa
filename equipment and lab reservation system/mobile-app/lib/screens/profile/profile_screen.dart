import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _studentEmployeeId = TextEditingController();
  final _department = TextEditingController();
  final _contactNumber = TextEditingController();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _service = AuthService();
  final _picker = ImagePicker();
  String? _photoPath;
  String? _message;
  String? _error;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = context.read<AuthProvider>().user;
    _firstName.text = user?.firstName ?? '';
    _lastName.text = user?.lastName ?? '';
    _email.text = user?.email ?? '';
    _studentEmployeeId.text = user?.studentEmployeeId ?? '';
    _department.text = user?.department ?? '';
    _contactNumber.text = user?.contactNumber ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _studentEmployeeId.dispose();
    _department.dispose();
    _contactNumber.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await _service.updateProfile({
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        'student_employee_id': _studentEmployeeId.text.trim(),
        'department': _department.text.trim(),
        'contact_number': _contactNumber.text.trim(),
      }, photoPath: _photoPath);
      await authProvider.reloadProfile();
      if (mounted) {
        setState(() {
          _message = 'Profile updated.';
          _error = null;
          _photoPath = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _message = null;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() => _saving = true);
    try {
      await _service.changePassword(_oldPassword.text, _newPassword.text);
      _oldPassword.clear();
      _newPassword.clear();
      if (mounted) {
        setState(() {
          _message = 'Password updated.';
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _message = null;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _choosePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image != null && mounted) setState(() => _photoPath = image.path);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundImage: _photoPath != null
                  ? FileImage(File(_photoPath!))
                  : user?.photo != null
                  ? NetworkImage(user!.photo!) as ImageProvider
                  : null,
              child: _photoPath == null && user?.photo == null
                  ? Text((user?.username ?? 'S').substring(0, 1).toUpperCase())
                  : null,
            ),
          ),
          OutlinedButton.icon(
            onPressed: _saving ? null : _choosePhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Choose profile photo'),
          ),
          const SizedBox(height: 12),
          Text(
            user?.username ?? 'Student',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('Role: ${user?.role ?? 'student'}'),
          TextField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'Last name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _studentEmployeeId,
            decoration: const InputDecoration(
              labelText: 'Student or employee ID',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _department,
            decoration: const InputDecoration(labelText: 'Department'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contactNumber,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact number'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _saving ? null : _saveProfile,
            child: const Text('Save profile'),
          ),
          const Divider(height: 32),
          TextField(
            controller: _oldPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _saving ? null : _changePassword,
            child: const Text('Change password'),
          ),
          if (_message != null)
            Text(_message!, style: const TextStyle(color: Colors.green)),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
