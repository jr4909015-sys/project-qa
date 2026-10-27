import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/reservation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReservationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final reservations = context.watch<ReservationProvider>();
    final firstName = user?.firstName.trim().isNotEmpty == true
        ? user!.firstName.trim()
        : user?.username ?? 'there';
    final activeCount = reservations.reservations
        .where((item) => item.status == 'pending' || item.status == 'approved')
        .length;
    final pendingCount = reservations.reservations
        .where((item) => item.status == 'pending')
        .length;
    final approvedCount = reservations.reservations
        .where((item) => item.status == 'approved')
        .length;
    final upcoming =
        reservations.reservations
            .where(
              (item) =>
                  (item.status == 'pending' || item.status == 'approved') &&
                  item.startAt.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final greeting = switch (DateTime.now().hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Reserve',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Profile',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.green.withValues(alpha: 0.12),
                child: Text(
                  firstName.isEmpty ? 'U' : firstName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reservations.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            _WelcomeCard(
              greeting: greeting,
              name: firstName,
              activeCount: activeCount,
              onReserve: () =>
                  Navigator.pushNamed(context, '/reservations/create'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Active bookings',
                    value: activeCount,
                    icon: Icons.event_available_rounded,
                    color: AppTheme.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Awaiting review',
                    value: pendingCount,
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFB66B12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Approved',
                    value: approvedCount,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF4467A9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SectionHeading(
              title: 'Explore',
              subtitle: 'Find the right space or equipment',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520 ? 4 : 2;
                final tileWidth =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionTile(
                      width: tileWidth,
                      label: 'Equipment',
                      description: 'Browse resources',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => Navigator.pushNamed(context, '/equipment'),
                    ),
                    _ActionTile(
                      width: tileWidth,
                      label: 'Laboratories',
                      description: 'Find a room',
                      icon: Icons.science_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, '/laboratories'),
                    ),
                    _ActionTile(
                      width: tileWidth,
                      label: 'My bookings',
                      description: 'Track requests',
                      icon: Icons.calendar_month_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, '/reservations'),
                    ),
                    _ActionTile(
                      width: tileWidth,
                      label: 'Borrowed items',
                      description: 'Check due dates',
                      icon: Icons.assignment_return_outlined,
                      onTap: () => Navigator.pushNamed(context, '/loans'),
                    ),
                    _ActionTile(
                      width: tileWidth,
                      label: 'Report a problem',
                      description: 'Tell staff about an issue',
                      icon: Icons.build_circle_outlined,
                      onTap: () => Navigator.pushNamed(context, '/issues'),
                    ),
                    if (user?.role == 'admin')
                      _ActionTile(
                        width: tileWidth,
                        label: 'Manage users',
                        description: 'Accounts and access',
                        icon: Icons.manage_accounts_outlined,
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin/users'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            _SectionHeading(
              title: 'Coming up',
              subtitle: 'Your next reservations',
              actionLabel: 'View all',
              onAction: () => Navigator.pushNamed(context, '/reservations'),
            ),
            const SizedBox(height: 12),
            if (reservations.isLoading && reservations.reservations.isEmpty)
              const _DashboardMessage(
                icon: Icons.sync_rounded,
                message: 'Loading your reservations…',
              )
            else if (reservations.error != null &&
                reservations.reservations.isEmpty)
              _DashboardMessage(
                icon: Icons.cloud_off_outlined,
                message: 'Reservations could not be loaded.',
                detail: reservations.error,
                actionLabel: 'Try again',
                onAction: reservations.load,
              )
            else if (upcoming.isEmpty)
              const _DashboardMessage(
                icon: Icons.event_note_outlined,
                message: 'Nothing booked yet',
                detail: 'Your upcoming equipment and laboratory reservations will appear here.',
              )
            else
              ...upcoming
                  .take(3)
                  .map(
                    (reservation) => _UpcomingReservationCard(
                      reservation: reservation,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/reservations/${reservation.id}',
                      ),
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/reservations/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New reservation'),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.greeting,
    required this.name,
    required this.activeCount,
    required this.onReserve,
  });

  final String greeting;
  final String name;
  final int activeCount;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF176B4B), Color(0xFF104B38)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -12,
          top: -22,
          child: Icon(
            Icons.science_outlined,
            size: 130,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              activeCount == 0
                  ? 'Ready to plan your next class or project?'
                  : 'You have $activeCount active ${activeCount == 1 ? 'booking' : 'bookings'} on the go.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onReserve,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Make a reservation'),
              style: FilledButton.styleFrom(
                foregroundColor: AppTheme.green,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFECEFEA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 10),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 23,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF737B75)),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF737B75)),
            ),
          ],
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.width,
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final double width;
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 116,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFECEFEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.green, size: 21),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF737B75)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFECEFEA)),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppTheme.green, size: 30),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (detail != null) ...[
          const SizedBox(height: 5),
          Text(
            detail!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF737B75)),
          ),
        ],
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}

class _UpcomingReservationCard extends StatelessWidget {
  const _UpcomingReservationCard({
    required this.reservation,
    required this.onTap,
  });

  final ReservationModel reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localStart = reservation.startAt.toLocal();
    final statusColor = reservation.status == 'approved'
        ? AppTheme.green
        : const Color(0xFFB66B12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFECEFEA)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${localStart.day}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.green,
                        ),
                      ),
                      Text(
                        _monthName(localStart.month),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.resourceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_time(localStart)} · ${reservation.confirmationNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF737B75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reservation.status == 'approved' ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _monthName(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

String _time(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}
