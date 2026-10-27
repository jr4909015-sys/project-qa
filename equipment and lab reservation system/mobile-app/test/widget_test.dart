// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_reservation_mobile/app.dart';
import 'package:school_reservation_mobile/models/user_model.dart';
import 'package:school_reservation_mobile/providers/auth_provider.dart';
import 'package:school_reservation_mobile/providers/reservation_provider.dart';
import 'package:school_reservation_mobile/services/auth_service.dart';

void main() {
  testWidgets('Login screen uses the branded sign-in layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(service: _TestAuthService()),
          ),
          ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ],
        child: const SchoolReservationApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username or school email'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

class _TestAuthService extends AuthService {
  @override
  Future<UserModel?> restoreSession() async => null;
}
