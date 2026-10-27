import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register({
      'username': _username.text.trim(),
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
    });
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Sign in to continue.')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Account access')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username'), validator: (value) => value == null || value.isEmpty ? 'Enter a username' : null),
            TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'First name')),
            TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last name')),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'School email'), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null),
            TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password (10+ characters)'), validator: (value) => value == null || value.length < 10 ? 'Use at least 10 characters' : null),
            const SizedBox(height: 16),
            Consumer<AuthProvider>(builder: (context, auth, _) => AppButton(label: 'Create student account', busy: auth.isLoading, onPressed: _submit)),
          ]),
        ),
      );
}