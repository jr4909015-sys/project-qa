import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_management_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _service = UserManagementService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  String _statusFilter = 'all';
  String? _error;
  bool _loading = true;
  int? _updatingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _service.list();
      if (mounted) setState(() => _users = users);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to load accounts: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      final payload = error.payload;
      if (payload is Map<String, dynamic>) {
        final detail = payload['detail'];
        if (detail is String) return detail;
        for (final value in payload.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String) return value;
        }
      }
    }
    return error.toString();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      final searchValues = [
        user['username'],
        user['email'],
        user['first_name'],
        user['last_name'],
        user['role_name'],
      ].whereType<String>();
      final matchesQuery =
          query.isEmpty ||
          searchValues.any((value) => value.toLowerCase().contains(query));
      final isActive = user['is_active'] == true;
      final matchesStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && isActive) ||
          (_statusFilter == 'inactive' && !isActive);
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _editUser({Map<String, dynamic>? user}) async {
    final formKey = GlobalKey<FormState>();
    final editingSelf = user?['id'] == context.read<AuthProvider>().user?.id;
    final username = TextEditingController(text: user?['username'] as String?);
    final email = TextEditingController(text: user?['email'] as String?);
    final firstName = TextEditingController(
      text: user?['first_name'] as String?,
    );
    final lastName = TextEditingController(text: user?['last_name'] as String?);
    final password = TextEditingController();
    var role = user?['role_name'] as String? ?? 'student';
    var isActive = user?['is_active'] as bool? ?? true;

    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Create account' : 'Edit account'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: username,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a username'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: firstName,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: lastName,
                      decoration: const InputDecoration(labelText: 'Last name'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: 'teacher',
                          child: Text('Teacher'),
                        ),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: editingSelf
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => role = value);
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: user == null
                            ? 'Password (at least 10 characters)'
                            : 'New password (optional)',
                      ),
                      validator: (value) {
                        if (user == null &&
                            (value == null || value.length < 10)) {
                          return 'Use at least 10 characters';
                        }
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 10) {
                          return 'Use at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      title: const Text('Account active'),
                      controlAffinity: ListTileControlAffinity.leading,
                      subtitle: editingSelf
                          ? const Text('Your account must remain active.')
                          : null,
                      onChanged: editingSelf
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => isActive = value);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final payload = <String, Object?>{
                  'username': username.text.trim(),
                  'email': email.text.trim(),
                  'first_name': firstName.text.trim(),
                  'last_name': lastName.text.trim(),
                  if (!editingSelf) 'role': role,
                  'is_active': editingSelf ? true : isActive,
                };
                if (password.text.isNotEmpty) {
                  payload['password'] = password.text;
                }
                Navigator.pop(dialogContext, payload);
              },
              child: Text(user == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    username.dispose();
    email.dispose();
    firstName.dispose();
    lastName.dispose();
    password.dispose();
    if (values == null || !mounted) return;

    setState(() => _updatingId = user?['id'] as int? ?? -1);
    try {
      if (user == null) {
        await _service.create(values);
      } else {
        await _service.update(user['id'] as int, values);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user == null ? 'Account created.' : 'Account updated.'),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Account could not be saved: ${_errorMessage(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final id = user['id'] as int;
    setState(() {
      _updatingId = id;
      _error = null;
    });
    try {
      final active = user['is_active'] == true;
      await _service.update(id, {'is_active': !active});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user['username']} ${active ? 'deactivated' : 'activated'}.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'Account status could not be updated: ${_errorMessage(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (context.watch<AuthProvider>().user?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('User management')),
        body: const Center(child: Text('Administrator access is required.')),
      );
    }

    final users = _filteredUsers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('User management'),
        actions: [
          IconButton(
            tooltip: 'Refresh accounts',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search accounts',
                hintText: 'Name, username, email, or role',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(labelText: 'Account status'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All accounts')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Deactivated')),
              ],
              onChanged: (value) =>
                  setState(() => _statusFilter = value ?? 'all'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: users.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Text(
                                  _users.isEmpty
                                      ? 'No user accounts found.'
                                      : 'No accounts match your filters.',
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: users.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final id = user['id'] as int;
                              final isActive = user['is_active'] == true;
                              final isCurrentUser = id == currentUserId;
                              final fullName =
                                  '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                                      .trim();
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      (user['username'] as String? ?? 'U')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                    ),
                                  ),
                                  title: Text(
                                    fullName.isEmpty
                                        ? user['username'] as String? ??
                                              'Unknown user'
                                        : '$fullName · ${user['username']}',
                                  ),
                                  subtitle: Text(
                                    '${user['email'] ?? 'No email'} · ${user['role_name'] ?? 'student'} · ${isActive ? 'Active' : 'Deactivated'}',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    enabled: _updatingId != id,
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _editUser(user: user);
                                      } else {
                                        _toggleActive(user);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit account'),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle',
                                        enabled: !isCurrentUser,
                                        child: Text(
                                          isActive ? 'Deactivate' : 'Activate',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _updatingId != null ? null : () => _editUser(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add user'),
      ),
    );
  }
}
