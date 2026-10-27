import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notifications;
  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _notifications = _service.list();
  }

  Future<void> _markRead(int id) async {
    try {
      await _service.markRead(id);
      if (mounted) setState(() => _notifications = _service.list());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification could not be updated: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: FutureBuilder<List<NotificationModel>>(
      future: _notifications,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load notifications.'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('You are all caught up.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              onTap: () async {
                if (item.readAt == null) await _markRead(item.id);
                if (item.reservationId != null && context.mounted) {
                  Navigator.pushNamed(
                    context,
                    '/reservations/${item.reservationId}',
                  );
                }
              },
              title: Text(item.title),
              subtitle: Text('${item.message}\n${item.createdAt.toLocal()}'),
              isThreeLine: true,
              trailing: item.readAt == null
                  ? IconButton(
                      tooltip: 'Mark read',
                      icon: const Icon(Icons.mark_email_read_outlined),
                      onPressed: () => _markRead(item.id),
                    )
                  : const Icon(Icons.done, size: 18),
            );
          },
        );
      },
    ),
  );
}
