import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

const _canvas = Color(0xFFFBFCF9);
const _forest = Color(0xFF183E32);
const _lime = Color(0xFFCCE56E);
const _muted = Color(0xFF737C75);
const _line = Color(0xFFDFE5DD);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _redirecting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_username.text.trim(), _password.text);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            auth.error?.contains('401') == true
                ? 'Sign-in failed. Check your username or school email and password.'
                : auth.error ?? 'Sign-in failed. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showPasswordResetDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSending = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset your password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your school email and we will send a recovery link if the account exists.',
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('School email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Enter a valid school email';
                    }
                    return null;
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFB33B32)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSending = true;
                        error = null;
                      });
                      try {
                        await AuthService().requestPasswordReset(
                          emailController.text.trim(),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'If the account exists, a reset link has been sent.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            isSending = false;
                            error = 'The reset request could not be sent. Try again.';
                          });
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send recovery link'),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.user != null && !_redirecting) {
            _redirecting = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            });
          }
          if (auth.isRestoring) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.green),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
                    Expanded(flex: 92, child: _buildAside()),
                    Expanded(
                      flex: 108,
                      child: SafeArea(
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 40,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 400,
                                    ),
                                    child: _buildSignInForm(auth),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 16,
                              ),
                              child: _buildLegal(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return SafeArea(
                child: LayoutBuilder(
                  builder: (context, pageConstraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: pageConstraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 26, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBrand(),
                            SizedBox(
                              height: (pageConstraints.maxHeight * .085).clamp(
                                42.0,
                                78.0,
                              ),
                            ),
                            _buildSignInForm(auth),
                            const SizedBox(height: 48),
                            _buildLegal(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBrand() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _brandMark(),
      const SizedBox(width: 11),
      const _BrandName(dark: true),
    ],
  );

  Widget _brandMark() => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _lime,
      borderRadius: BorderRadius.circular(9),
    ),
    child: const Text(
      'S',
      style: TextStyle(
        color: _forest,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _buildAside() => ClipRect(
    child: ColoredBox(
      color: _forest,
      child: Stack(
        children: [
          Positioned(right: -245, top: 100, child: _orbit(510)),
          Positioned(right: -185, top: 175, child: _orbit(390)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brandMark(),
                    const SizedBox(width: 11),
                    const _BrandName(dark: false),
                  ],
                ),
                const Spacer(flex: 2),
                const Text(
                  'NORTH CAMPUS',
                  style: TextStyle(
                    color: _lime,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Make room for\nwhat matters.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 355),
                  child: Text(
                    'One place to find the equipment and spaces that help great ideas take shape.',
                    style: TextStyle(
                      color: Color(0xFFC2D1C7),
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                const _ReservationIllustration(),
                const Spacer(flex: 2),
                const Text(
                  'A better way to share campus resources.',
                  style: TextStyle(color: Color(0xFFA9C4B3), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _orbit(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
  );

  Widget _buildSignInForm(AuthProvider auth) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'YOUR CAMPUS, IN REACH',
          style: TextStyle(
            color: Color(0xFF477A58),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Welcome back',
          style: TextStyle(
            color: Color(0xFF202723),
            fontSize: 34,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 11),
        const Text(
          'Sign in to manage your reservations and discover campus resources.',
          style: TextStyle(color: _muted, fontSize: 13, height: 1.65),
        ),
        const SizedBox(height: 29),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FieldLabel('Username or school email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _username,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: _inputDecoration('Enter your username or email'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your username or email'
                    : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: _FieldLabel('Password')),
                  TextButton(
                    onPressed: _showPasswordResetDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.green,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: _inputDecoration('Enter your password').copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                      color: _muted,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 21),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.green.withValues(
                      alpha: .7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          children: [
                            Spacer(),
                            Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward, size: 19),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'New to CampusReserve? ',
              style: TextStyle(color: Color(0xFF606A62), fontSize: 12),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.green,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Create an account',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Need help accessing your account? Contact your campus administrator.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF929A93), fontSize: 10, height: 1.6),
        ),
      ],
    );

    return AutofillGroup(child: content);
  }

  Widget _buildLegal() => Text(
    '© ${DateTime.now().year} North Campus  ·  Equipment & Lab Reservations',
    textAlign: TextAlign.center,
    style: TextStyle(color: Color(0xFF929A93), fontSize: 10),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFA0A8A1), fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFF43805C), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFFB33B32)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFFB33B32), width: 1.4),
    ),
  );
}

class _BrandName extends StatelessWidget {
  const _BrandName({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: 'Campus',
      children: [
        TextSpan(
          text: 'Reserve',
          style: TextStyle(
            color: dark ? const Color(0xFFA9C4B3) : const Color(0xFFA9C4B3),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    style: TextStyle(
      color: dark ? const Color(0xFF202723) : Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF39443C),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ReservationIllustration extends StatelessWidget {
  const _ReservationIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 205,
    child: Stack(
      children: [
        Positioned(
          left: 42,
          top: 35,
          child: Transform.rotate(
            angle: -.14,
            child: Container(
              width: 240,
              height: 145,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                border: Border.all(color: Colors.white.withValues(alpha: .18)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IllustrationLine(width: 190),
                  SizedBox(height: 14),
                  _IllustrationLine(width: 145),
                  SizedBox(height: 14),
                  _IllustrationLine(width: 100),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 105,
          top: 12,
          child: Transform.rotate(
            angle: .09,
            child: Container(
              width: 220,
              height: 165,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9F4),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 35,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _lime,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'S',
                      style: TextStyle(
                        color: _forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  const _IllustrationLine(width: 150, light: true),
                  const SizedBox(height: 9),
                  const _IllustrationLine(width: 105, light: true),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 34,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF81B18C),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 18,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _lime, width: 4),
            ),
          ),
        ),
      ],
    ),
  );
}

class _IllustrationLine extends StatelessWidget {
  const _IllustrationLine({required this.width, this.light = false});

  final double width;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 7,
    decoration: BoxDecoration(
      color: light
          ? const Color(0xFFDCE5DA)
          : Colors.white.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(5),
    ),
  );
}
