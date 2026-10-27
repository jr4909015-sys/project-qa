import 'package:flutter/material.dart';

import '../models/reservation_model.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation, this.onTap, this.onCancel});

  final ReservationModel reservation;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final resource = reservation.equipmentId != null ? 'Equipment' : 'Laboratory';
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(reservation.resourceName == 'Reservation' ? '$resource reservation' : reservation.resourceName),
        subtitle: Text('${reservation.startAt.toLocal()} · ${reservation.purpose}${reservation.remarks.isEmpty ? '' : '\nReview: ${reservation.remarks}'}'),
        isThreeLine: true,
        trailing: onCancel == null
            ? Text(reservation.status)
            : IconButton(
                tooltip: 'Cancel reservation',
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
              ),
        onTap: onTap,
      ),
    );
  }
}