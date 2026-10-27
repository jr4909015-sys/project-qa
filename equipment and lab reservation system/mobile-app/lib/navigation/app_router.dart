import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/equipment/equipment_list_screen.dart';
import '../screens/equipment/equipment_details_screen.dart';
import '../screens/equipment/my_borrowed_equipment_screen.dart';
import '../screens/laboratories/laboratory_list_screen.dart';
import '../screens/laboratories/laboratory_details_screen.dart';
import '../screens/reservations/create_reservation_screen.dart';
import '../screens/reservations/my_reservations_screen.dart';
import '../screens/reservations/reservation_details_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/issues/issue_report_screen.dart';

class AppRouter {
  static const login = '/login';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    '/register': (_) => const RegisterScreen(),
    '/dashboard': (_) => const DashboardScreen(),
    '/equipment': (_) => const EquipmentListScreen(),
    '/loans': (_) => const MyBorrowedEquipmentScreen(),
    '/laboratories': (_) => const LaboratoryListScreen(),
    '/reservations': (_) => const MyReservationsScreen(),
    '/reservations/create': (_) => const CreateReservationScreen(),
    '/profile': (_) => const ProfileScreen(),
    '/notifications': (_) => const NotificationsScreen(),
    '/admin/users': (_) => const UserManagementScreen(),
    '/issues': (_) => const IssueReportScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final path = settings.name ?? '';
    if (path.startsWith('/equipment/')) {
      return MaterialPageRoute<void>(
        builder: (_) =>
            EquipmentDetailsScreen(id: int.tryParse(path.split('/').last) ?? 0),
      );
    }
    if (path.startsWith('/laboratories/')) {
      return MaterialPageRoute<void>(
        builder: (_) => LaboratoryDetailsScreen(
          id: int.tryParse(path.split('/').last) ?? 0,
        ),
      );
    }
    if (path.startsWith('/reservations/')) {
      return MaterialPageRoute<void>(
        builder: (_) => ReservationDetailsScreen(
          id: int.tryParse(path.split('/').last) ?? 0,
        ),
      );
    }
    return null;
  }
}
